-- =====================================================================
-- クローズドβの成功指標(投稿頻度・リピート率)をメンバーにも見せる。
-- 「投稿」はスレッド(group_posts, 0020/0029)への書き込みを対象とする
-- (ゴール関連の活動はメンバー単位でgroup_member_activity(0018)が
-- 既にcompletedGoalsCount/lastActiveAtとして可視化しているため対象外)。
-- =====================================================================

create or replace function public.get_group_activity_stats(p_group_id uuid, p_weeks integer default 8)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_weeks integer := least(greatest(coalesce(p_weeks, 8), 1), 26);
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'weeklyPostCounts', (
      select coalesce(jsonb_agg(to_jsonb(w) order by w."weekStart"), '[]'::jsonb)
      from (
        select
          gs::date as "weekStart",
          (
            select count(*) from public.group_posts p
            where p.group_id = p_group_id
              and date_trunc('week', p.created_at) = gs
          )::int as count
        from generate_series(
          date_trunc('week', now()) - ((v_weeks - 1) || ' weeks')::interval,
          date_trunc('week', now()),
          '1 week'::interval
        ) gs
      ) w
    ),
    'repeatRate', (
      select case when count(*) filter (where weeks_active >= 1) = 0 then 0
        else round(
          count(*) filter (where weeks_active >= 2)::numeric
          / count(*) filter (where weeks_active >= 1),
          2
        )
      end
      from (
        select author_id, count(distinct date_trunc('week', created_at)) as weeks_active
        from public.group_posts
        where group_id = p_group_id
          and created_at >= now() - (v_weeks || ' weeks')::interval
        group by author_id
      ) s
    )
  );
end;
$$;

grant execute on function public.get_group_activity_stats(uuid, integer) to authenticated;
