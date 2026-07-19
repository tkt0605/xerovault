-- =====================================================================
-- 除名(remove_member)を永続化する。
--
-- これまでremove_memberはgroup_membersの行を削除するだけで、除名の事実を
-- どこにも記録していなかった。公開グループはトークンなしで参加できるため、
-- 除名されたユーザーがjoin_groupを呼び直すだけで即座に再参加できてしまい、
-- オーナーの除名の意図が公開グループに対しては無効化されていた。
-- group_bansで除名を記録し、join_groupで再参加を拒否する。
-- オーナーはunban_memberで解除できる。
-- =====================================================================

create table public.group_bans (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  banned_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

alter table public.group_bans enable row level security;

create policy "group_bans visible to owner"
  on public.group_bans for select
  to authenticated
  using (exists (select 1 from public.groups where id = group_id and owner_id = auth.uid()));

-- ---------------------------------------------------------------------
-- remove_member: 除名時にgroup_bansへ記録する
-- ---------------------------------------------------------------------
create or replace function public.remove_member(p_group_id uuid, p_member_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
begin
  select owner_id into v_owner_id from public.groups where id = p_group_id;
  if v_owner_id is null then
    raise exception 'グループが存在しません' using errcode = 'P0002';
  end if;
  if v_owner_id <> auth.uid() then
    raise exception '除名権限がありません' using errcode = '42501';
  end if;
  if p_member_id = v_owner_id then
    raise exception 'オーナーを除名できません' using errcode = '22023';
  end if;

  delete from public.group_members where group_id = p_group_id and user_id = p_member_id;

  insert into public.group_bans (group_id, user_id)
  values (p_group_id, p_member_id)
  on conflict (group_id, user_id) do update set banned_at = now();
end;
$$;

grant execute on function public.remove_member(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- join_group: 除名済みユーザーの再参加を拒否する
-- ---------------------------------------------------------------------
create or replace function public.join_group(p_group_id uuid, p_token text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group public.groups;
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

  if not v_group.is_public then
    if p_token is null or v_group.join_token is null or v_group.join_token <> p_token then
      raise exception '無効なトークンです' using errcode = '22023';
    end if;
    if v_group.join_token_expires_at is null or v_group.join_token_expires_at < now() then
      raise exception '招待リンクの有効期限が切れています' using errcode = '22023';
    end if;
  end if;

  insert into public.group_members (group_id, user_id) values (p_group_id, auth.uid());

  return public.get_group_detail(p_group_id);
end;
$$;

grant execute on function public.join_group(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- get_banned_members / unban_member: オーナー向けの禁止リスト管理
-- ---------------------------------------------------------------------
create or replace function public.get_banned_members(p_group_id uuid)
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
        'id', p.id, 'name', p.name, 'avatar', p.avatar,
        'bannedAt', b.banned_at
      ) order by b.banned_at desc
    )
    from public.group_bans b
    join public.profiles p on p.id = b.user_id
    where b.group_id = p_group_id
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_banned_members(uuid) to authenticated;

create or replace function public.unban_member(p_group_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.groups where id = p_group_id and owner_id = auth.uid()) then
    raise exception 'オーナーのみ解除できます' using errcode = '42501';
  end if;

  delete from public.group_bans where group_id = p_group_id and user_id = p_user_id;
end;
$$;

grant execute on function public.unban_member(uuid, uuid) to authenticated;
