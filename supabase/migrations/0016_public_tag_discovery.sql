-- =====================================================================
-- 公開グループのタグ発見機能
-- - get_public_tag_stats: 公開グループで使われているタグを件数順に返す
-- - get_rankings: 任意のタグで絞り込めるように拡張する
-- =====================================================================

create or replace function public.get_public_tag_stats(p_limit integer default 12)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from (
    select tag, count(*) as "groupCount"
    from public.groups g, unnest(g.tags) as tag
    where g.is_public = true
    group by tag
    order by count(*) desc, tag asc
    limit least(greatest(coalesce(p_limit, 12), 1), 50)
  ) t;
$$;

grant execute on function public.get_public_tag_stats(integer) to authenticated, anon;

-- ---------------------------------------------------------------------
-- get_rankings: p_tag による絞り込みに対応
-- ---------------------------------------------------------------------
drop function if exists public.get_rankings(integer);

create or replace function public.get_rankings(p_limit integer default 20, p_tag text default null)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from (
    select
      g.id, g.name, g.tags, g.score, g.streak, g.created_at as "createdAt",
      jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar) as owner,
      jsonb_build_object(
        'members', (select count(*) from public.group_members gm where gm.group_id = g.id),
        'goals', (select count(*) from public.goals gl where gl.group_id = g.id)
      ) as "_count"
    from public.groups g
    join public.profiles o on o.id = g.owner_id
    where g.is_public = true
      and (p_tag is null or p_tag = any(g.tags))
    order by g.score desc
    limit least(greatest(coalesce(p_limit, 20), 1), 100)
  ) t;
$$;

grant execute on function public.get_rankings(integer, text) to authenticated, anon;
