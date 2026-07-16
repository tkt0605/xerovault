-- =====================================================================
-- セキュリティ修正: profiles.UPDATEがテーブル単位で付与されたままだった
--
-- 0010でSELECTは列単位に絞り込んだが、UPDATEは手つかずだった。
-- RLSは行単位(id = auth.uid())のみで列を制限しないため、ログイン中の
-- ユーザーがsupabase.from('profiles').update({ email: '...', is_active: true })
-- を直接叩くと、emailやis_activeを検証なしで書き換えられてしまう
-- (emailはSupabase Authの正規の確認フローを経ずに変わる/is_activeは将来の
-- アカウント停止機能を自分で無効化できてしまう、という実害がある)。
--
-- フロントが実際にクライアントから直接updateしているのはSettings.vueの
-- name(表示名)とnotifications_enabled(通知on/off)の2列のみなので、
-- SELECTと同じ「テーブル単位を一旦REVOKEし、必要な列だけ列単位でGRANT」
-- パターンで塞ぐ。email/avatar/is_active/unsubscribe_token等は
-- クライアントから直接更新できなくなる(将来必要になれば専用RPCを作る)。
-- =====================================================================

revoke update on public.profiles from authenticated, anon;
grant update (name, notifications_enabled) on public.profiles to authenticated;
