-- =====================================================================
-- タグの表記ゆれ対策(「筋トレ」「筋トレ部」「筋トレ好き」への分裂を防ぐ)。
-- グループタグ・個人興味タグの両方から既存タグを集計して返し、
-- フロントの入力欄でオートコンプリート候補として使う。
-- =====================================================================

create or replace function public.get_all_tags(p_limit integer default 100)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from (
    select tag, count(*) as "usageCount"
    from (
      select unnest(tags) as tag from public.groups
      union all
      select unnest(interest_tags) as tag from public.profiles
    ) all_tags
    group by tag
    order by count(*) desc, tag asc
    limit least(greatest(coalesce(p_limit, 100), 1), 200)
  ) t;
$$;

grant execute on function public.get_all_tags(integer) to authenticated;
