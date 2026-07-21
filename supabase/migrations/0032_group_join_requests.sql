-- =====================================================================
-- 招待の「選ばれた感」を出すための申請制ウェイトリスト。
--
-- オーナーの直接招待リンク(create_invite/join_group)は既存のまま残し、
-- 別経路として「申請ページのURLを共有 → 応募者がメッセージ付きで申請 →
-- オーナーが承認/却下」のフローを追加する。承認されたユーザーのみ
-- group_membersに入る。却下されたら同じグループへの再申請はできない
-- (オーナーから直接招待リンクをもらう既存経路は引き続き使える)。
-- =====================================================================

create table public.group_join_requests (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  message text check (char_length(message) <= 200),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  unique (group_id, user_id)
);

create index idx_group_join_requests_group_id on public.group_join_requests (group_id);

alter table public.group_join_requests enable row level security;

-- 書き込みはすべてSECURITY DEFINERなRPC経由(group_bansと同じ設計)。
-- 閲覧のみ、申請者本人かグループオーナーに許可する
create policy "group_join_requests visible to requester or owner"
  on public.group_join_requests for select
  to authenticated
  using (
    user_id = auth.uid()
    or exists (select 1 from public.groups where id = group_id and owner_id = auth.uid())
  );

-- ---------------------------------------------------------------------
-- create_join_request: 参加申請を1件作成し、オーナーに通知する
-- ---------------------------------------------------------------------
create or replace function public.create_join_request(p_group_id uuid, p_message text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group public.groups;
  v_request public.group_join_requests;
begin
  select * into v_group from public.groups where id = p_group_id;
  if v_group.id is null then
    raise exception 'グループが存在しません' using errcode = 'P0002';
  end if;

  if exists (select 1 from public.group_members where group_id = p_group_id and user_id = auth.uid()) then
    raise exception 'すでに参加しています' using errcode = '23505';
  end if;

  if exists (select 1 from public.group_bans where group_id = p_group_id and user_id = auth.uid()) then
    raise exception 'このグループには参加できません' using errcode = '42501';
  end if;

  if exists (select 1 from public.group_join_requests where group_id = p_group_id and user_id = auth.uid()) then
    raise exception 'すでに参加をリクエスト済みです' using errcode = '23505';
  end if;

  insert into public.group_join_requests (group_id, user_id, message)
  values (p_group_id, auth.uid(), nullif(trim(p_message), ''))
  returning * into v_request;

  insert into public.notification_log (user_id, kind, group_join_request_id)
  values (v_group.owner_id, 'join_request', v_request.id);

  return jsonb_build_object(
    'id', v_request.id,
    'groupId', v_request.group_id,
    'status', v_request.status,
    'createdAt', v_request.created_at
  );
end;
$$;

grant execute on function public.create_join_request(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- get_group_join_request_target: 未メンバーでも呼べる、申請ページ表示用の
-- 安全な最小限の情報(名前・説明・タグ・自分の申請ステータスのみ)
-- ---------------------------------------------------------------------
create or replace function public.get_group_join_request_target(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_group public.groups;
  v_status text;
begin
  select * into v_group from public.groups where id = p_group_id;
  if v_group.id is null then
    raise exception 'グループが見つかりません' using errcode = 'P0002';
  end if;

  select status into v_status
  from public.group_join_requests
  where group_id = p_group_id and user_id = auth.uid();

  return jsonb_build_object(
    'id', v_group.id,
    'name', v_group.name,
    'description', v_group.description,
    'tags', v_group.tags,
    'myRequestStatus', v_status
  );
end;
$$;

grant execute on function public.get_group_join_request_target(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- get_group_join_requests / approve_join_request / reject_join_request:
-- オーナー向けの申請管理
-- ---------------------------------------------------------------------
create or replace function public.get_group_join_requests(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if not exists (select 1 from public.groups where id = p_group_id and owner_id = auth.uid()) then
    raise exception 'オーナーのみ閲覧できます' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'user', jsonb_build_object('id', p.id, 'email', p.email, 'name', p.name, 'avatar', p.avatar),
        'message', r.message,
        'createdAt', r.created_at
      ) order by r.created_at asc
    )
    from public.group_join_requests r
    join public.profiles p on p.id = r.user_id
    where r.group_id = p_group_id and r.status = 'pending'
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_group_join_requests(uuid) to authenticated;

create or replace function public.approve_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.group_join_requests;
  v_owner_id uuid;
begin
  select * into v_request from public.group_join_requests where id = p_request_id;
  if v_request.id is null then
    raise exception '申請が見つかりません' using errcode = 'P0002';
  end if;

  select owner_id into v_owner_id from public.groups where id = v_request.group_id;
  if v_owner_id <> auth.uid() then
    raise exception 'オーナーのみ承認できます' using errcode = '42501';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'この申請は既に処理済みです' using errcode = '22023';
  end if;

  insert into public.group_members (group_id, user_id)
  values (v_request.group_id, v_request.user_id)
  on conflict do nothing;

  update public.group_join_requests
  set status = 'approved', decided_at = now()
  where id = p_request_id;

  insert into public.notification_log (user_id, kind, group_join_request_id)
  values (v_request.user_id, 'join_approved', p_request_id);
end;
$$;

grant execute on function public.approve_join_request(uuid) to authenticated;

create or replace function public.reject_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.group_join_requests;
  v_owner_id uuid;
begin
  select * into v_request from public.group_join_requests where id = p_request_id;
  if v_request.id is null then
    raise exception '申請が見つかりません' using errcode = 'P0002';
  end if;

  select owner_id into v_owner_id from public.groups where id = v_request.group_id;
  if v_owner_id <> auth.uid() then
    raise exception 'オーナーのみ却下できます' using errcode = '42501';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'この申請は既に処理済みです' using errcode = '22023';
  end if;

  update public.group_join_requests
  set status = 'rejected', decided_at = now()
  where id = p_request_id;

  insert into public.notification_log (user_id, kind, group_join_request_id)
  values (v_request.user_id, 'join_rejected', p_request_id);
end;
$$;

grant execute on function public.reject_join_request(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- notification_log拡張: join_request/join_approved/join_rejectedに対応する
-- (0028_group_post_reply_notificationsでreply用に緩めたのと同じ形)
-- ---------------------------------------------------------------------
alter table public.notification_log
  add column group_join_request_id uuid references public.group_join_requests (id) on delete cascade;

alter table public.notification_log
  drop constraint notification_log_kind_check;

alter table public.notification_log
  add constraint notification_log_kind_check
  check (kind in (
    'pending_vote', 'deadline_approaching', 'missed', 'reply',
    'join_request', 'join_approved', 'join_rejected'
  ));

alter table public.notification_log
  drop constraint notification_log_target_check;

alter table public.notification_log
  add constraint notification_log_target_check
  check (
    (kind = 'reply' and group_post_id is not null and goal_id is null and group_join_request_id is null)
    or (
      kind in ('join_request', 'join_approved', 'join_rejected')
      and group_join_request_id is not null and goal_id is null and group_post_id is null
    )
    or (
      kind not in ('reply', 'join_request', 'join_approved', 'join_rejected')
      and goal_id is not null and group_post_id is null and group_join_request_id is null
    )
  );

create unique index notification_log_join_request_unique
  on public.notification_log (user_id, group_join_request_id)
  where kind in ('join_request', 'join_approved', 'join_rejected');

-- ---------------------------------------------------------------------
-- get_my_notifications: join_request系の行をgroup_join_requests/groups/profilesから補完する
-- ---------------------------------------------------------------------
create or replace function public.get_my_notifications(p_limit integer default 30)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t) order by t."sentAt" desc), '[]'::jsonb)
  from (
    select
      nl.id,
      nl.kind,
      nl.sent_at as "sentAt",
      nl.read_at as "readAt",
      g.id as "goalId",
      g.header as "goalHeader",
      g.description as "goalDescription",
      coalesce(goalgrp.id, postgrp.id, reqgrp.id) as "groupId",
      coalesce(goalgrp.name, postgrp.name, reqgrp.name) as "groupName",
      coalesce(gp.parent_post_id, gp.id) as "postId",
      gp.text as "replyText",
      ra.name as "replierName",
      gjr.id as "joinRequestId",
      gjr.message as "joinRequestMessage",
      requester.name as "requesterName"
    from public.notification_log nl
    left join public.goals g on g.id = nl.goal_id
    left join public.groups goalgrp on goalgrp.id = g.group_id
    left join public.group_posts gp on gp.id = nl.group_post_id
    left join public.groups postgrp on postgrp.id = gp.group_id
    left join public.profiles ra on ra.id = gp.author_id
    left join public.group_join_requests gjr on gjr.id = nl.group_join_request_id
    left join public.groups reqgrp on reqgrp.id = gjr.group_id
    left join public.profiles requester on requester.id = gjr.user_id
    where nl.user_id = auth.uid()
    order by nl.sent_at desc
    limit p_limit
  ) t;
$$;

grant execute on function public.get_my_notifications(integer) to authenticated;
