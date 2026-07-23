# リビルドTodo — マーケ戦略とのすり合わせ

> 前提: Andrew Chenのコールドスタート理論に基づき「①アトミックネットワーク形成 → ②ビルダー発信 → ③アンバサダー化 → ④認知拡大」の順で進める戦略と、現状のコードベースを照らし合わせた結果のTodo。
>
> **フェーズ0で軸を確定済み(2026-07-20)**: xerovaultの核は「タグベースのマッチング/発見」ではなく、既存実装の「グループ内ゴール管理・アカウンタビリティ機能」(`docs/vision.md`)とする。タグは現状の完全一致フィルタのままでよく、類似度マッチングはフェーズ3以降に後回し。

## フェーズ0: 戦略前提の確認・意思決定 — 完了

- [x] 「タグ類似度マッチング」ではなく「既存のゴール管理・アカウンタビリティ機能」を軸に確定
- [x] タグは現状のシンプルな完全一致のままで問題なし、類似度マッチングは将来フェーズへ後回し

## フェーズ1: ①招待制クローズドβをゴール管理アプリとして実装

- [x] `supabase/migrations/0017_public_group_self_join.sql` によりトークンなしで参加できる公開グループ導線(`is_public = true`)を閉じる(`0031_close_public_group_self_join.sql`で対応。グループ作成時のデフォルトは元々非公開だったため変更不要)
- [x] `0016_public_tag_discovery.sql` の `get_rankings`/`get_public_tag_stats` によるランキング画面からの公開グループ発見導線を、β期間中は一時的に隠す(Aside.vue/router/Home.vueから導線を削除。DB側のRPCは復活しやすいよう残置)
- [x] 招待の入り口に「選ばれた感」を出すUI/導線を追加する(`0032_group_join_requests.sql`で申請制ウェイトリストを実装。`/group/:id/request`から申請 → オーナーが承認/却下 → 通知)
- [x] 最初のクローズドβ対象クラスタを確定: **個人開発者コミュニティ**。招待する具体的な10〜20人の選定・声かけはユーザー(タカトさん)側のタスクとして残る
- [x] 成功指標(投稿頻度・リピート率)を計測できる状態にする(`0033_group_activity_stats.sql`の`get_group_activity_stats`でグループ内メンバーにも「活動」タブとして表示)

## フェーズ2: ②ビルダー発信のための素材化

- [x] RLS脆弱性修正の開発ログ化 — `docs/dev-log-rls-security.md`に、`cc16d2a`→`86e67f8`→`d39db4a`→`0858b2f`→`a16158f`を時系列のストーリーとしてまとめた(根本原因: PostgreSQLの列単位権限はテーブル単位の許可を狭められないという性質の見落とし)
- [x] `docs/score-design.md` の設計思想を発信素材にする — 同ファイル冒頭に「発信用サマリー」節を追加(「曖昧な目標を許さない」「自己申告を許さない」「未解決の課題を隠さない」の3点)
- [x] `docs/vision.md` のターゲット像を統一する — CLAUDE.mdの旧タグライン(「共通の趣味嗜好を持つ仲間と出会い」)をゴール管理・アカウンタビリティ軸に書き換え、`vision.md`にもフェーズ0の軸決定への参照を追記
- [x] Zenn記事のドラフトを作成(動画は選定せず) — `~/articles/xerovault-goal-accountability-and-rls-mistakes.md`(`published: false`)。設計思想(score-design)とRLSの試行錯誤(dev-log)の両方を1本にまとめた

## フェーズ3以降: ③アンバサダー化・タグ精緻化・④認知拡大

- [ ] タグの精緻化(表記ゆれ吸収、興味タグの重なり度によるグループ推薦などの類似度マッチング)は①②が固まってから着手する。現時点では手をつけない
- [ ] 初期ユーザーをアンバサダー化する施策を検討する(招待制のまま「選ばれた」体験を維持しつつ、招待権限の一部委譲などを検討)
- [ ] ブランディング(ロゴ/LP/デザインシステム)は④のフェーズに入るまで着手しない(現状ゼロ工数で、戦略と一致している状態を維持する)
- [x] 改名を決定・実行済み(2026-07-23決定、2026-07-24に製品名を2回更新): 社名は「Anythink」、本プロダクト名は「Xerovault」から「Sodalis」に変更(Apple/Macのような社名・製品名の二層構造)。決定の変遷: 「Commit」(個人開発者ターゲットとgit commitの重なりを狙う)→「Pact」(グループでの約束という核と直結する語)→「Sodalis」(2026-07-24)。「曖昧な目標を許さない」核ではなくStreak機能寄りに読めるため「Streak」は不採用。
  - **実行済み(2026-07-24)**: GitHubリポジトリ名(`xerovault`→`sodalis`)・Vercelプロジェクト名(`sodalis`)・コード内のパッケージスコープ(`@xerovault/shared`→`@sodalis/shared`、全import文・pnpm-lock.yaml追従済み)・UI表示文言・Edge Function(notify-digest/unsubscribe)のメール表示名・README/CLAUDE.md/vision.mdの表示名を全てリネーム済み。フロントエンドのlint/tsc/buildは全て通過を確認済み
  - **未着手のまま維持**: Supabaseプロジェクト名(`gzikcrnwesidipsnwbqy`)のリネームのみ、当初方針通りフェーズ④着手時まで保留(Supabaseはプロジェクト名変更がURL/接続情報に直結しないため急ぐ必要性が低い)。本ファイルの過去日付付き記述(フェーズ0確定時の引用等)と`supabase/migrations/0001_init.sql`のコメントは、当時の正確な記録として意図的に未変更

## その他 / 技術的な整理(優先度低・随時)

- [x] `.env.production` に残る旧Django/Nuxt/Azure構成の変数(`DJANGO_SECRET_KEY`, `AZURE_DATABASE_URL`, `NUXT_PUBLIC_API_BASE` など)を削除する。②で開発ログを対外公開する前に棚卸しする
- [x] `.devcontainer/devcontainer.json` の旧Python/Expressバックエンド向け設定を整理する(`CLAUDE.md` に既知の課題として記載済み)
