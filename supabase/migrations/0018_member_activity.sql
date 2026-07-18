-- =====================================================================
-- 仲間探しは「グループの実績スコア」だけでなく「人」単位の解像度が要る。
-- 自己紹介文(bio)と、メンバーごとの活動指標(達成数・最終活動日)を
-- get_group_detail / get_my_groups の members に追加する。
-- 会話内容(messagesの中身)は非公開のまま、活動の有無だけを可視化する。
-- =====================================================================

alter table public.profiles add column bio text check (char_length(bio) <= 160);

-- 0014でテーブル単位のUPDATEは既にREVOKE済みなので、列単位のGRANTを追加するだけでよい
grant update (bio) on public.profiles to authenticated;

-- メンバー単位の活動集計。group_last_activity_at(0007)と同じ発想の動的算出ヘルパー。
-- get_group_detail / get_my_groups からのみ内部利用するためauthenticated/anonには公開しない
create or replace function public.group_member_activity(p_group_id uuid, p_user_id uuid)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select jsonb_build_object(
    'completedGoalsCount', (
      select count(*) from public.goals
      where group_id = p_group_id and assignee_id = p_user_id and is_completed = true
    ),
    'lastActiveAt', nullif(greatest(
      coalesce(
        (select max(g.updated_at) from public.goals g where g.group_id = p_group_id and g.assignee_id = p_user_id),
        '-infinity'::timestamptz
      ),
      coalesce(
        (select max(m.created_at)
         from public.messages m
         join public.goals g on g.id = m.goal_id
         where g.group_id = p_group_id and m.author_id = p_user_id),
        '-infinity'::timestamptz
      ),
      coalesce(
        (select max(v.created_at)
         from public.votes v
         join public.goals g on g.id = v.goal_id
         where g.group_id = p_group_id and v.voter_id = p_user_id),
        '-infinity'::timestamptz
      )
    ), '-infinity'::timestamptz)
  );
$$;

-- ---------------------------------------------------------------------
-- get_group_detail: membersにbio/completedGoalsCount/lastActiveAtを追加
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
    'tags', g.tags,
    'isPublic', g.is_public,
    'score', g.score,
    'streak', g.streak,
    'joinToken', g.join_token,
    'createdAt', g.created_at,
    'updatedAt', g.updated_at,
    'lastActivityAt', public.group_last_activity_at(g.id),
    'owner', jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar),
    'members', (
      select coalesce(jsonb_agg(
        jsonb_build_object('id', mp.id, 'email', mp.email, 'name', mp.name, 'avatar', mp.avatar, 'bio', mp.bio)
          || public.group_member_activity(g.id, mp.id)
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

-- ---------------------------------------------------------------------
-- get_my_groups: 同様にmembersを拡張(型の一貫性のため)
-- ---------------------------------------------------------------------
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
      g.tags,
      g.is_public as "isPublic",
      g.score,
      g.streak,
      g.join_token as "joinToken",
      g.created_at as "createdAt",
      g.updated_at as "updatedAt",
      public.group_last_activity_at(g.id) as "lastActivityAt",
      jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar) as owner,
      (
        select coalesce(jsonb_agg(
          jsonb_build_object('id', mp.id, 'email', mp.email, 'name', mp.name, 'avatar', mp.avatar, 'bio', mp.bio)
            || public.group_member_activity(g.id, mp.id)
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
