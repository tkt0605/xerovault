-- =====================================================================
-- セキュリティレビュー: profilesへの直接SELECTがanonロールにも列単位で
-- 付与されたままだった(0010でSupabaseのデフォルトGRANT ALLを列制限に
-- 絞り込んだ際、対象を authenticated, anon の両方にしていた名残)。
--
-- 現状profilesにはanon向けのRLS SELECTポリシーが存在しないため、実際には
-- anonでSELECTしても0件になり実害はない(確認済み)。また、フロントエンドで
-- profilesを直接select しているのは auth.ts / Settings.vue / GroupDetail.vue
-- のみで、いずれもログイン後(authenticated)のコンテキストに限られる。
-- 公開ページ(Ranking.vue等)はget_rankings/get_public_tag_stats等の
-- SECURITY DEFINER RPC経由であり、呼び出し元ロールのGRANTとは無関係。
--
-- つまりanonの列GRANTは現状使われておらず、将来profilesにanon向けの
-- RLSポリシーを誤って追加してしまった場合(0025のget_rankings漏洩と同種の
-- ミス)に備え、多層防御として今のうちに塞いでおく。
-- =====================================================================

revoke select on public.profiles from anon;
