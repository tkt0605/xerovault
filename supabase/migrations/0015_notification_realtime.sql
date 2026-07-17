-- =====================================================================
-- アプリ内通知にRealtimeを適用する
--
-- notification_logはこれまでRPC経由のみ(直接テーブルへのSELECTポリシー
-- なし)としていたが、Supabase Realtimeのpostgres_changesは購読者の
-- RLS SELECT可否で配信をフィルタするため、ポリシーが無いままでは
-- リアルタイムイベントを一切受け取れない。votes/messagesと同じ
-- 「本人(または関係者)の行だけ見える」スコープのポリシーを追加し、
-- publicationにテーブルを加える。
--
-- get_my_notifications等の既存RPCはSECURITY DEFINERで直接テーブルの
-- RLSをバイパスするため、このポリシー追加による既存機能への影響はない。
-- =====================================================================

create policy "notifications visible to owner"
  on public.notification_log for select
  to authenticated
  using (user_id = auth.uid());

alter publication supabase_realtime add table public.notification_log;
