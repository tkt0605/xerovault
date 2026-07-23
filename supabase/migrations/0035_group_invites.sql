-- =====================================================================
-- 招待リンクを単一トークン(groups.join_token)方式から、複数発行・個別
-- 失効可能なgroup_invitesテーブル方式に置き換える。
--
-- 従来はcreate_inviteを呼ぶたびに既存トークンを上書きしていたため、
-- 「具体的に10〜20人を選んで招待する」運用(docs/rebuild.md フェーズ1)に
-- 対応できなかった。1コード=1回のみ使用可・個別expiry・個別revokeに変える。
-- =====================================================================

create table public.group_invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  token text not null unique,
  created_by uuid not null references public.profiles (id) on delete cascade,
  expires_at timestamptz not null,
  used_by uuid references public.profiles (id) on delete set null,
  used_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_group_invites_group_id on public.group_invites (group_id);

alter table public.group_invites enable row level security;

create policy "group_invites visible to owner"
  on public.group_invites for select
  to authenticated
  using (exists (select 1 from public.groups where id = group_id and owner_id = auth.uid()));

-- ---------------------------------------------------------------------
-- create_invite: 招待コードを1件発行する(既存コードは失効させない)
-- 戻り値をtext(トークンのみ)からjsonb(id/token/expiresAt)に変えるため
-- create or replaceではなく明示的にdropしてから作り直す
-- ---------------------------------------------------------------------
drop function if exists public.create_invite(uuid, integer);

create or replace function public.create_invite(p_group_id uuid, p_expire_in integer default 3600)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.group_invites;
begin
  if not exists (select 1 from public.groups where id = p_group_id and owner_id = auth.uid()) then
    raise exception '招待権限がありません' using errcode = '42501';
  end if;

  insert into public.group_invites (group_id, token, created_by, expires_at)
  values (
    p_group_id,
    encode(extensions.gen_random_bytes(16), 'hex'),
    auth.uid(),
    now() + make_interval(secs => p_expire_in)
  )
  returning * into v_invite;

  return jsonb_build_object(
    'id', v_invite.id,
    'token', v_invite.token,
    'expiresAt', v_invite.expires_at,
    'createdAt', v_invite.created_at
  );
end;
$$;

grant execute on function public.create_invite(uuid, integer) to authenticated;

-- ---------------------------------------------------------------------
-- get_group_invites / revoke_invite: オーナー向けの招待コード管理
-- ---------------------------------------------------------------------
create or replace function public.get_group_invites(p_group_id uuid)
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
        'id', i.id,
        'token', i.token,
        'expiresAt', i.expires_at,
        'createdAt', i.created_at
      ) order by i.created_at desc
    )
    from public.group_invites i
    where i.group_id = p_group_id
      and i.used_at is null
      and i.revoked_at is null
      and i.expires_at > now()
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_group_invites(uuid) to authenticated;

create or replace function public.revoke_invite(p_invite_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  select group_id into v_group_id from public.group_invites where id = p_invite_id;
  if v_group_id is null then
    raise exception '招待コードが見つかりません' using errcode = 'P0002';
  end if;

  if not exists (select 1 from public.groups where id = v_group_id and owner_id = auth.uid()) then
    raise exception 'オーナーのみ失効できます' using errcode = '42501';
  end if;

  update public.group_invites set revoked_at = now() where id = p_invite_id;
end;
$$;

grant execute on function public.revoke_invite(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- join_group: group_invitesを参照するように更新。for updateで対象行を
-- ロックし、同一コードの同時使用による二重消費(1コード1回の前提崩れ)を防ぐ
-- ---------------------------------------------------------------------
create or replace function public.join_group(p_group_id uuid, p_token text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group public.groups;
  v_invite public.group_invites;
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

  if p_token is null then
    raise exception '無効なトークンです' using errcode = '22023';
  end if;

  select * into v_invite
  from public.group_invites
  where group_id = p_group_id and token = p_token
  for update;

  if v_invite.id is null or v_invite.revoked_at is not null or v_invite.used_at is not null then
    raise exception '無効なトークンです' using errcode = '22023';
  end if;
  if v_invite.expires_at < now() then
    raise exception '招待リンクの有効期限が切れています' using errcode = '22023';
  end if;

  update public.group_invites set used_at = now(), used_by = auth.uid() where id = v_invite.id;

  insert into public.group_members (group_id, user_id) values (p_group_id, auth.uid());

  return public.get_group_detail(p_group_id);
end;
$$;

grant execute on function public.join_group(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- 旧単一トークン方式のカラムを撤去。フロントでは未参照のため実害なし
-- (get_group_detail/get_my_groupsは0021_group_description.sql時点の定義から
-- 'joinToken'の組み立てだけを除去する。それ以外のロジックは変更しない)
-- ---------------------------------------------------------------------
create or replace function public.get_group_detail(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'id', g.id,
    'name', g.name,
    'description', g.description,
    'tags', g.tags,
    'isPublic', g.is_public,
    'score', g.score,
    'streak', g.streak,
    'createdAt', g.created_at,
    'updatedAt', g.updated_at,
    'lastActivityAt', public.group_last_activity_at(g.id),
    'owner', jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar),
    'members', (
      select coalesce(jsonb_agg(
        jsonb_build_object(
          'id', mp.id, 'email', mp.email, 'name', mp.name, 'avatar', mp.avatar,
          'bio', mp.bio, 'interestTags', mp.interest_tags
        ) || public.group_member_activity(g.id, mp.id)
      ), '[]'::jsonb)
      from public.group_members gm
      join public.profiles mp on mp.id = gm.user_id
      where gm.group_id = g.id
    ),
    '_count', jsonb_build_object('goals', (select count(*) from public.goals where group_id = g.id))
  )
  into v_result
  from public.groups g
  join public.profiles o on o.id = g.owner_id
  where g.id = p_group_id;

  if v_result is null then
    raise exception 'グループが存在しません' using errcode = 'P0002';
  end if;

  return v_result;
end;
$$;

grant execute on function public.get_group_detail(uuid) to authenticated;

create or replace function public.get_my_groups()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t) order by t."updatedAt" desc), '[]'::jsonb)
  from (
    select
      g.id,
      g.name,
      g.description,
      g.tags,
      g.is_public as "isPublic",
      g.score,
      g.streak,
      g.created_at as "createdAt",
      g.updated_at as "updatedAt",
      public.group_last_activity_at(g.id) as "lastActivityAt",
      jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar) as owner,
      (
        select coalesce(jsonb_agg(
          jsonb_build_object(
            'id', mp.id, 'email', mp.email, 'name', mp.name, 'avatar', mp.avatar,
            'bio', mp.bio, 'interestTags', mp.interest_tags
          ) || public.group_member_activity(g.id, mp.id)
        ), '[]'::jsonb)
        from public.group_members gm2
        join public.profiles mp on mp.id = gm2.user_id
        where gm2.group_id = g.id
      ) as members,
      jsonb_build_object('goals', (select count(*) from public.goals gl where gl.group_id = g.id)) as "_count"
    from public.groups g
    join public.profiles o on o.id = g.owner_id
    where g.owner_id = auth.uid()
       or exists (select 1 from public.group_members gm where gm.group_id = g.id and gm.user_id = auth.uid())
  ) t;
$$;

grant execute on function public.get_my_groups() to authenticated;

alter table public.groups drop column join_token;
alter table public.groups drop column join_token_expires_at;
