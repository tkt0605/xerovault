-- =====================================================================
-- P2: 復帰導線の複線化(アプリ内通知 + プロフィール設定の土台)
--
-- (1) アプリ内通知: notification_logにread_atを追加し、一覧・未読数・
--     既読化のRPCを新設する。テーブル自体には引き続きRLSポリシーを
--     追加しない(default deny)。全てSECURITY DEFINER RPC経由でauth.uid()の
--     行のみ参照・更新できるようにする(このリポジトリの他テーブルと同じ
--     「RPCのみが書き込み・参照経路」方針を踏襲)。
--
-- (2) セキュリティ修正: 0008で追加したprofiles.unsubscribe_tokenは、
--     既存の "profiles are viewable by authenticated users" ポリシー
--     (using (true)、列制限なし)により、全認証済みユーザーから閲覧可能に
--     なってしまっていた。unsubscribe_tokenが分かれば他人の通知配信を
--     無断で停止できてしまうため、この列だけ列単位でREVOKEする。
-- =====================================================================

alter table public.notification_log add column read_at timestamptz;

revoke select (unsubscribe_token) on public.profiles from authenticated, anon;

create or replace function public.get_my_notifications(p_limit integer default 30)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t) order by t."sentAt" desc), '[]'::jsonb)
  from (
    select
      nl.id,
      nl.kind,
      nl.sent_at as "sentAt",
      nl.read_at as "readAt",
      g.id as "goalId",
      g.header as "goalHeader",
      g.description as "goalDescription",
      grp.id as "groupId",
      grp.name as "groupName"
    from public.notification_log nl
    join public.goals g on g.id = nl.goal_id
    join public.groups grp on grp.id = g.group_id
    where nl.user_id = auth.uid()
    order by nl.sent_at desc
    limit p_limit
  ) t;
$$;

grant execute on function public.get_my_notifications(integer) to authenticated;

create or replace function public.get_unread_notification_count()
returns integer
language sql
security definer
stable
set search_path = public
as $$
  select count(*)::integer
  from public.notification_log
  where user_id = auth.uid() and read_at is null;
$$;

grant execute on function public.get_unread_notification_count() to authenticated;

-- p_idsを省略すると自分の未読を全件既読にする
create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns void
language sql
security definer
set search_path = public
as $$
  update public.notification_log
  set read_at = now()
  where user_id = auth.uid()
    and read_at is null
    and (p_ids is null or id = any(p_ids));
$$;

grant execute on function public.mark_notifications_read(uuid[]) to authenticated;
