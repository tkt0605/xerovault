-- =====================================================================
-- 個人の興味タグ。「あなたと嗜好が近い人」をGroupDetailのメンバーカードで
-- ハイライトできるようにする(表記ゆれ対策は別タスク、今回は自由入力のまま)。
-- =====================================================================

alter table public.profiles add column interest_tags text[] not null default '{}';

-- 0014でテーブル単位のUPDATEは既にREVOKE済みなので、列単位のGRANTを追加するだけでよい
grant update (interest_tags) on public.profiles to authenticated;

-- ---------------------------------------------------------------------
-- get_group_detail: membersにinterestTagsを追加
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

-- ---------------------------------------------------------------------
-- get_my_groups: 同様にinterestTagsを追加
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
