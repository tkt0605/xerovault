-- =====================================================================
-- 層2 追加: 通知の空気感調整（日次ダイジェスト化 + 1タップ配信停止）
--
-- - notify-digestの実行頻度を毎時→日次（JST 19時）に変更。
--   notification_logのunique(user_id, goal_id, kind)制約により、そもそも
--   同じ通知は生涯一度しか送られない設計なので、頻度を落としても
--   実装ロジックの変更は不要（cronのスケジュール式のみ変更）。
-- - profiles.notifications_enabled / unsubscribe_token を追加し、
--   メール本文末尾のリンクからログイン不要でワンタップ配信停止できるようにする。
--   unsubscribe_tokenは推測困難なuuidをそのまま照合キーとして使う
--   （HMAC署名などは少人数向けアプリの規模には過剰と判断）。
-- - profilesは既存の "users can update own profile" ポリシーにより
--   本人が直接updateできるため、notifications_enabledの
--   アプリ内トグルは将来追加する場合も新規RPCは不要。
-- =====================================================================

alter table public.profiles
  add column notifications_enabled boolean not null default true,
  add column unsubscribe_token uuid not null default gen_random_uuid();

create unique index idx_profiles_unsubscribe_token on public.profiles (unsubscribe_token);

-- 戻り値の列（unsubscribe_token追加）が変わるため、create or replaceでは変更できず
-- 一度dropしてから再作成する必要がある
drop function if exists public.get_notification_candidates();

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
  deadline timestamptz,
  unsubscribe_token uuid
)
language sql
security definer
stable
set search_path = public
as $$
  -- 投票待ち: pendingなconcrete goalのうち、goal_votesにレコードがないメンバー
  select
    gm.user_id, p.email, p.name, 'pending_vote'::text, g.id, g.header, g.description,
    g.group_id, grp.name, g.deadline, p.unsubscribe_token
  from public.goals g
  join public.groups grp on grp.id = g.group_id
  join public.group_members gm on gm.group_id = g.group_id
  join public.profiles p on p.id = gm.user_id
  where p.notifications_enabled
    and g.is_concrete and g.is_completed = false and g.deadline >= now()
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
    g.group_id, grp.name, g.deadline, p.unsubscribe_token
  from public.goals g
  join public.groups grp on grp.id = g.group_id
  join public.group_members gm on gm.group_id = g.group_id
  join public.profiles p on p.id = gm.user_id
  where p.notifications_enabled
    and g.is_concrete and g.is_completed = false
    and g.deadline >= now() and g.deadline < now() + interval '24 hours'
    and not exists (
      select 1 from public.notification_log nl
      where nl.user_id = gm.user_id and nl.goal_id = g.id and nl.kind = 'deadline_approaching'
    )

  union all

  -- 新規missed: 期限切れになった未達成concrete goal
  select
    gm.user_id, p.email, p.name, 'missed'::text, g.id, g.header, g.description,
    g.group_id, grp.name, g.deadline, p.unsubscribe_token
  from public.goals g
  join public.groups grp on grp.id = g.group_id
  join public.group_members gm on gm.group_id = g.group_id
  join public.profiles p on p.id = gm.user_id
  where p.notifications_enabled
    and g.is_concrete and g.is_completed = false and g.deadline < now()
    and not exists (
      select 1 from public.notification_log nl
      where nl.user_id = gm.user_id and nl.goal_id = g.id and nl.kind = 'missed'
    );
$$;

grant execute on function public.get_notification_candidates() to service_role;

-- 配信停止（unsubscribe Edge Functionからservice_roleで呼ばれる）
create or replace function public.disable_notifications_by_token(p_token uuid)
returns boolean
language sql
security definer
volatile
set search_path = public
as $$
  update public.profiles
  set notifications_enabled = false
  where unsubscribe_token = p_token
  returning true;
$$;

grant execute on function public.disable_notifications_by_token(uuid) to service_role;

-- ---------------------------------------------------------------------
-- 実行頻度を毎時→日次（JST 19:00 = UTC 10:00）に変更
-- ---------------------------------------------------------------------

select cron.unschedule(jobid) from cron.job where jobname = 'notify-digest';

select cron.schedule(
  'notify-digest',
  '0 10 * * *', -- 毎日UTC10:00 = JST19:00
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
