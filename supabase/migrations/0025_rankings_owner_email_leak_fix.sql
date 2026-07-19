-- =====================================================================
-- セキュリティ修正: get_rankingsが未ログインユーザー(anon)にも
-- グループオーナーのemailを返してしまっていた。
--
-- get_rankingsはget_group_detailのowner表現(id/email/name/avatar)を
-- そのまま流用していたが、get_group_detailはメンバー限定で見せる情報、
-- get_rankingsは0001_init.sqlの時点からanonにもgrant executeされている
-- 公開の発見/ランキング用エンドポイントであり、性質が異なる。
-- フロント(Ranking.vue)もowner.emailを表示に使っておらず、単純な過剰露出
-- だったため、ownerからemailを除外する。
-- =====================================================================

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
      g.id, g.name, g.description, g.tags, g.score, g.streak, g.created_at as "createdAt",
      jsonb_build_object('id', o.id, 'name', o.name, 'avatar', o.avatar) as owner,
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
