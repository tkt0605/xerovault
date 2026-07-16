-- =====================================================================
-- P3: 個人の実績ビュー
--
-- 「完了させたゴール数」「投票参加率」を返すRPC。常にauth.uid()自身の
-- 実績のみを返すため、group_id等のアクセスチェックは不要。
-- =====================================================================

create or replace function public.get_my_stats()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select jsonb_build_object(
    'completedGoalsCount', (
      select count(*) from public.goals where assignee_id = auth.uid() and is_completed = true
    ),
    'totalVotableGoals', (
      select count(*)
      from public.goals g
      join public.group_members gm on gm.group_id = g.group_id
      where gm.user_id = auth.uid()
    ),
    'votedGoalsCount', (
      select count(*) from public.goal_votes where voter_id = auth.uid()
    )
  );
$$;

grant execute on function public.get_my_stats() to authenticated;
