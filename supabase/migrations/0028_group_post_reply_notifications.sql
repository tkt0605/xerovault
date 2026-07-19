-- =====================================================================
-- 掲示板投稿への返信を、既存のアプリ内通知(notification_log)に統合する。
--
-- これまでnotification_logはゴール関連(投票待ち・締切間近・missed)の
-- goal_id必須の行しか想定していなかった。返信はゴールに紐付かないため、
-- goal_id/group_post_idのどちらか一方だけが埋まる形に緩め、
-- kindに'reply'を追加する。
--
-- 既存のunique(user_id, goal_id, kind)はgoal_idがnullだと重複を防げない
-- ため、reply用に別途部分一意インデックスを追加する。
-- =====================================================================

alter table public.notification_log alter column goal_id drop not null;

alter table public.notification_log
  add column group_post_id uuid references public.group_posts (id) on delete cascade;

alter table public.notification_log
  drop constraint notification_log_kind_check;

alter table public.notification_log
  add constraint notification_log_kind_check
  check (kind in ('pending_vote', 'deadline_approaching', 'missed', 'reply'));

alter table public.notification_log
  add constraint notification_log_target_check
  check (
    (kind = 'reply' and group_post_id is not null and goal_id is null)
    or (kind <> 'reply' and goal_id is not null and group_post_id is null)
  );

create unique index notification_log_reply_unique
  on public.notification_log (user_id, group_post_id)
  where kind = 'reply';

-- ---------------------------------------------------------------------
-- create_group_post: 返信作成時、元投稿の投稿者に通知を記録する
-- (自分自身の投稿への返信、または既に削除された投稿への返信は通知しない)
-- ---------------------------------------------------------------------
create or replace function public.create_group_post(
  p_group_id uuid,
  p_text text,
  p_parent_post_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post public.group_posts;
  v_parent public.group_posts;
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  if p_parent_post_id is not null then
    select * into v_parent from public.group_posts where id = p_parent_post_id;
    if v_parent.id is null or v_parent.group_id <> p_group_id then
      raise exception '返信先の投稿が見つかりません' using errcode = 'P0002';
    end if;
    if v_parent.parent_post_id is not null then
      raise exception '返信への返信はできません' using errcode = '22023';
    end if;
  end if;

  insert into public.group_posts (group_id, author_id, text, parent_post_id)
  values (p_group_id, auth.uid(), trim(p_text), p_parent_post_id)
  returning * into v_post;

  if v_parent.id is not null and v_parent.author_id <> auth.uid() then
    insert into public.notification_log (user_id, kind, group_post_id)
    values (v_parent.author_id, 'reply', v_post.id)
    on conflict (user_id, group_post_id) where kind = 'reply' do nothing;
  end if;

  return jsonb_build_object(
    'id', v_post.id,
    'text', v_post.text,
    'createdAt', v_post.created_at,
    'groupId', v_post.group_id,
    'authorId', v_post.author_id,
    'parentPostId', v_post.parent_post_id,
    'author', (select jsonb_build_object('id', id, 'email', email, 'name', name, 'avatar', avatar) from public.profiles where id = auth.uid()),
    'replies', '[]'::jsonb
  );
end;
$$;

grant execute on function public.create_group_post(uuid, text, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- get_my_notifications: reply行はgroup_posts/groups/profilesから補完する
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
      coalesce(goalgrp.id, postgrp.id) as "groupId",
      coalesce(goalgrp.name, postgrp.name) as "groupName",
      gp.id as "postId",
      gp.text as "replyText",
      ra.name as "replierName"
    from public.notification_log nl
    left join public.goals g on g.id = nl.goal_id
    left join public.groups goalgrp on goalgrp.id = g.group_id
    left join public.group_posts gp on gp.id = nl.group_post_id
    left join public.groups postgrp on postgrp.id = gp.group_id
    left join public.profiles ra on ra.id = gp.author_id
    where nl.user_id = auth.uid()
    order by nl.sent_at desc
    limit p_limit
  ) t;
$$;

grant execute on function public.get_my_notifications(integer) to authenticated;
