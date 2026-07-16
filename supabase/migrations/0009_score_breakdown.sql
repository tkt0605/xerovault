-- =====================================================================
-- P1: スコア内訳の可視化(バックエンド側)
--
-- recalc_group_score内の計算ロジックをcalc_score_breakdown()に切り出し、
-- recalc_group_scoreはそれを呼んでUPDATEするだけにする(ロジックの二重管理を避ける)。
-- calc_score_breakdownはアクセスチェックなしの内部関数(pg_cronからauth.uid()
-- なしで呼ばれるため、is_group_memberのようなauth.uid()依存のチェックを
-- 挟むとcronからの呼び出しが全滅する)。フロント向けには、アクセスチェック付きの
-- ラッパーget_score_breakdownを別途公開する。
--
-- オーナー向けメンバー削除UIについて: remove_member RPCは0001_init.sqlで
-- 実装済み・フロントから未接続なだけだったため、バックエンド変更は不要。
-- =====================================================================

create or replace function public.calc_score_breakdown(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_total_members integer;
  v_completed_points integer;
  v_missed_count integer;
  v_missed_penalty integer;
  v_streak integer := 0;
  v_streak_bonus integer := 0;
  v_trailing boolean := true;
  v_total integer;
  rec record;
begin
  select count(*) into v_total_members from public.group_members where group_id = p_group_id;

  select coalesce(sum(
    round(
      (case when g.is_concrete then 25 else 5 end) *
      (case when v_total_members > 0 and (
        (select count(distinct gv.voter_id)
         from public.goal_votes gv
         join public.votes v on v.goal_vote_id = gv.id
         where gv.goal_id = g.id)::numeric / v_total_members
      ) >= 1.0 then 1.5 else 1.0 end)
    )
  ), 0)::integer
  into v_completed_points
  from public.goals g
  where g.group_id = p_group_id and g.is_completed = true;

  select count(*) into v_missed_count
  from public.goals g
  where g.group_id = p_group_id
    and g.is_concrete
    and g.is_completed = false
    and g.deadline < now();

  v_missed_penalty := v_missed_count * 25;

  for rec in
    select is_completed
    from public.goals
    where group_id = p_group_id
      and is_concrete
      and (is_completed = true or deadline < now())
    order by deadline desc
  loop
    if v_trailing and rec.is_completed then
      v_streak := v_streak + 1;
    else
      v_trailing := false;
    end if;
  end loop;

  v_streak_bonus := case when v_streak >= 3 then 50 else 0 end;

  v_total := greatest(0, least(100 + v_completed_points - v_missed_penalty + v_streak_bonus, 9999));

  return jsonb_build_object(
    'base', 100,
    'completedPoints', v_completed_points,
    'missedCount', v_missed_count,
    'missedPenalty', v_missed_penalty,
    'streak', v_streak,
    'streakBonus', v_streak_bonus,
    'total', v_total
  );
end;
$$;

-- pg_cron(recalc_all_group_scores経由)やcast_vote等のSECURITY DEFINER関数
-- からのみ呼ばれる内部関数のため、authenticated/anonには公開しない

create or replace function public.recalc_group_score(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_breakdown jsonb;
begin
  v_breakdown := public.calc_score_breakdown(p_group_id);
  update public.groups
  set score = (v_breakdown ->> 'total')::integer,
      streak = (v_breakdown ->> 'streak')::integer,
      updated_at = now()
  where id = p_group_id;
end;
$$;

-- フロント向け: アクセスチェック付きで内訳を返す
create or replace function public.get_score_breakdown(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  return public.calc_score_breakdown(p_group_id);
end;
$$;

grant execute on function public.get_score_breakdown(uuid) to authenticated;
