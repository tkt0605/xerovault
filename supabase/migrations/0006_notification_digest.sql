-- =====================================================================
-- 層2: 通知（投票待ち・期限接近・新規missed）
--
-- SQLだけではメール送信できないため、実際の送信は
-- supabase/functions/notify-digest（Edge Function）が担う。
-- ここでは (1) 冪等性を担保するnotification_logテーブル、
-- (2) Edge Functionに渡す通知候補を集計するRPC、
-- (3) pg_cron + pg_netで毎時Edge Functionを叩くスケジュール、を用意する。
--
-- 差分検知について: 「前回実行時との差分」を取るための専用カラム
-- （最終通知時刻など）は追加していない。notification_log の
-- unique(user_id, goal_id, kind) 制約そのものが「このユーザーに
-- このゴールのこの種別を通知済みか」を表すため、これ自体が
-- 差分検知（＝毎時実行しても重複送信しない冪等性担保）を兼ねる。
-- =====================================================================

create extension if not exists pg_net with schema extensions;

create table public.notification_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  goal_id uuid not null references public.goals (id) on delete cascade,
  kind text not null check (kind in ('pending_vote', 'deadline_approaching', 'missed')),
  sent_at timestamptz not null default now(),
  unique (user_id, goal_id, kind)
);

create index idx_notification_log_user_id on public.notification_log (user_id);
create index idx_notification_log_goal_id on public.notification_log (goal_id);

alter table public.notification_log enable row level security;
-- アプリのUIからは読み書きしない。Edge Functionがservice_roleで直接read/writeする前提のため
-- ポリシーは一切作らず、anon/authenticatedからは常にアクセス不可（default deny）にする。

-- 通知候補（まだnotification_logに記録のない投票待ち・期限接近・新規missed）を
-- 行単位（ユーザー×ゴール×種別）で返す。Edge Function専用の内部関数のため
-- authenticated/anonには公開せず、service_roleのみ実行可能にする。
create or replace function public.get_notification_candidates()
returns table (
  user_id uuid,
  email text,
  name text,
  kind text,
  goal_id uuid,
  goal_header text,
  goal_description text,
  group_id uuid,
  group_name text,
  deadline timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  -- 投票待ち: pendingなconcrete goalのうち、goal_votesにレコードがないメンバー
  select
    gm.user_id, p.email, p.name, 'pending_vote'::text, g.id, g.header, g.description,
    g.group_id, grp.name, g.deadline
  from public.goals g
  join public.groups grp on grp.id = g.group_id
  join public.group_members gm on gm.group_id = g.group_id
  join public.profiles p on p.id = gm.user_id
  where g.is_concrete and g.is_completed = false and g.deadline >= now()
    and not exists (
      select 1 from public.goal_votes gv where gv.goal_id = g.id and gv.voter_id = gm.user_id
    )
    and not exists (
      select 1 from public.notification_log nl
      where nl.user_id = gm.user_id and nl.goal_id = g.id and nl.kind = 'pending_vote'
    )

  union all

  -- 期限接近: pendingなconcrete goalでdeadlineが24時間以内に迫っているもの
  select
    gm.user_id, p.email, p.name, 'deadline_approaching'::text, g.id, g.header, g.description,
    g.group_id, grp.name, g.deadline
  from public.goals g
  join public.groups grp on grp.id = g.group_id
  join public.group_members gm on gm.group_id = g.group_id
  join public.profiles p on p.id = gm.user_id
  where g.is_concrete and g.is_completed = false
    and g.deadline >= now() and g.deadline < now() + interval '24 hours'
    and not exists (
      select 1 from public.notification_log nl
      where nl.user_id = gm.user_id and nl.goal_id = g.id and nl.kind = 'deadline_approaching'
    )

  union all

  -- 新規missed: 期限切れになった未達成concrete goal
  select
    gm.user_id, p.email, p.name, 'missed'::text, g.id, g.header, g.description,
    g.group_id, grp.name, g.deadline
  from public.goals g
  join public.groups grp on grp.id = g.group_id
  join public.group_members gm on gm.group_id = g.group_id
  join public.profiles p on p.id = gm.user_id
  where g.is_concrete and g.is_completed = false and g.deadline < now()
    and not exists (
      select 1 from public.notification_log nl
      where nl.user_id = gm.user_id and nl.goal_id = g.id and nl.kind = 'missed'
    );
$$;

grant execute on function public.get_notification_candidates() to service_role;

-- ---------------------------------------------------------------------
-- pg_cronから毎時Edge Functionを叩く。
--
-- 注意: Edge FunctionのURLとservice_role keyはこのファイルに実値を書かない
-- （gitに秘匿情報をコミットしないため）。代わりにSupabase Vaultに登録した
-- シークレットを名前で参照する。初回セットアップ時にSQL Editorで
-- 一度だけ実行しておくこと（実値はプレースホルダを置き換えて実行、
-- migrationファイルには含めない）:
--
--   select vault.create_secret('https://<project-ref>.functions.supabase.co/notify-digest', 'notify_digest_url');
--   select vault.create_secret('<service_role key>', 'notify_digest_service_role_key');
-- ---------------------------------------------------------------------

select cron.unschedule(jobid) from cron.job where jobname = 'notify-digest';

select cron.schedule(
  'notify-digest',
  '5 * * * *', -- 毎時5分（recalc-all-group-scoresの0分と重ならないようずらす）
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'notify_digest_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'notify_digest_service_role_key')
    ),
    body := '{}'::jsonb
  ) as request_id;
  $$
);
