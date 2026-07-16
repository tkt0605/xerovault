-- =====================================================================
-- 層1: score/streakの定期再計算（基盤）
--
-- 現状 recalc_group_score() は cast_vote / cancel_vote からしか呼ばれない。
-- そのため「投票が起きない」グループは、期限切れによるmissedペナルティや
-- streak途切れが groups.score / groups.streak に反映されないまま凍結し続ける
-- （calc_goal_status 等の"表示"は live 計算なので嘘にならないが、集計値である
-- score/streak は永続化された値を返すため、再計算されるまで古いまま）。
--
-- pg_cronで全グループを定期的に recalc_group_score にかけることで、
-- 投票の有無に関係なくscore/streakを最新の状態に保つ。
-- 通知機能などスコアを前提にした機能より先に、この土台を直す。
-- =====================================================================

create extension if not exists pg_cron with schema extensions;

-- 全グループのscore/streakを再計算する。cronジョブ専用の内部関数のため
-- 他のRPCと異なり authenticated/anon には grant しない（アプリからは呼ばせない）。
-- 1グループの再計算が失敗しても他のグループに影響しないよう、グループ単位で
-- 例外を握りつぶし警告ログに残す（一括SELECTだと1件の失敗で全体がロールバックするため）。
create or replace function public.recalc_all_group_scores()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  for v_group_id in select id from public.groups loop
    begin
      perform public.recalc_group_score(v_group_id);
    exception when others then
      raise warning 'recalc_group_score failed for group %: %', v_group_id, sqlerrm;
    end;
  end loop;
end;
$$;

-- 再実行時に重複スケジュールされないよう、同名ジョブがあれば一度消してから登録する
select cron.unschedule(jobid) from cron.job where jobname = 'recalc-all-group-scores';

select cron.schedule(
  'recalc-all-group-scores',
  '0 * * * *', -- 1時間おき
  $$ select public.recalc_all_group_scores() $$
);
