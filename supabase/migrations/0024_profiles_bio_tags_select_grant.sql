-- =====================================================================
-- セキュリティレビューで発覚した不整合の修正。
--
-- 0010でprofilesのSELECTを列単位ホワイトリスト化した際、その後追加された
-- bio(0018)・interest_tags(0019)がホワイトリストに含まれていなかった。
-- UPDATE側は正しくgrant update (column)パターンを踏襲していたが、SELECT側の
-- 追加漏れにより、クライアントからの直接select(Settings.vue/GroupDetail.vue)
-- が権限エラーで失敗し、保存済みのbio/興味タグが読み込めない状態になっていた
-- (RPC経由のget_group_detail等はSECURITY DEFINERのため影響を受けていない)。
-- =====================================================================

grant select (bio, interest_tags) on public.profiles to authenticated;
