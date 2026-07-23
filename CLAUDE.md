# Sodalis
グループ内で立てた目標を、メンバー全員の投票による合意形成で達成扱いにする、正直な目標管理・アカウンタビリティアプリ。自己申告に頼らず、曖昧な目標を許さない(詳細は`docs/vision.md`)。
※ タグベースの「共通の趣味嗜好を持つ仲間探し」ではない(フェーズ0で軸を確定済み、`docs/rebuild.md`参照)。タグは現状シンプルな完全一致フィルタとしてのみ機能する。

## スタイル
- コミットメッセージの規約: 
- 命名規則: 
- ディレクトリ・ファイル構成: 
- コンポーネントの設計方針: 
- エラーハンドリング方針: 
- コメント・ドキュメント言語: 日本語で出力

## コマンド
- `pnpm install `: 依存パッケージをインストールする。pnpm workspacesを使用中。ルートで実行すれば、各パッケージの依存が解消。
- `docker compose up --build`: Dockerイメージをビルドしてから開発環境を起動する。よってfrontendコンテナが立ち上がり、localhost:5173にアクセスできる。
- `pnpm run lint`: ESLintでコードの解析を行、混在的バグやエラー、規約違反を検出する。
- `pnpm run format:check`: Prettierでフォーマットが規約通りか確認する。
- `npx vue-tsc --noEmit`: Vue用のTypescriptコンパイラでフロントエンドの型チェックのみを行う。
- `pnpm run build`:  本番用にViteでフロントエンドをビルドする(最適化・バンドルされた静的ファイルを生成)。

## アーキテクチャ
### モノレポ構成 (pnpm workspaces)
- frontend/ — Vue 3 + Vite SPA
- packages/shared/ — zodスキーマ・型定義 (@sodalis/shared)
- supabase/ — DBスキーマ・RLS・RPC・Edge Functions(旧Expressバックエンドを置換済み、backend/は現存しない)

### 言語・ランタイム
- Node.js v22 (Docker: node:22-alpine)
- pnpm 11.7.0 (corepack管理)
- TypeScript ^5.6.0

### フロントエンド
- Vue 3.5 + Vite 8 + vue-router 4 + Pinia 2(状態管理)
- Tailwind CSS 3.4 + PostCSS + Autoprefixer
- ESLint 10 (typescript-eslint, eslint-plugin-vue) + Prettier 3.9
- vue-tsc(型チェック)

### バックエンド/インフラ
- Supabase(Auth・Postgres・RLS・RPC・Edge Functions・pg_cron)。専用バックエンドサーバーは無し
- Supabase CLI ^2.109.1
- Resend(通知メール送信用API)

### 開発/CI
- Docker Compose(make devでfrontendコンテナ起動、ポート5173)
- GitHub Actions CI(.github/workflows/ci.yml): shared側tsc --noEmit、frontend側 lint/format:check/vue-tsc/build
- .devcontainer/devcontainer.json はfrontendサービス(Node/pnpm)向けに整理済み

## 規約
- PR/ブランチ運用: mainへの直push禁止、ブランチ命名規則、レビュー必須の有無
- テスト方針: テストの有無・要否(このプロジェクトは現状テストコマンドが見当たらないので「テストは書かない/書く場合は〇〇」など明記すると良い)
- RLS/セキュリティのルール: Supabaseを使っているので「新規テーブルには必ずRLSを設定する」「RPCは〇〇の権限チェックを必須とする」など、直近の脆弱性修正コミット(fix: profiles.UPDATEが...)を踏まえたルール化
- マイグレーション運用: supabase/migrations/の命名規則(00XX_説明.sql)、ローカルでの検証手順
- 環境変数・シークレット管理: .envの扱い、Resend APIキーなどの管理方法
- 依存追加のルール: 新規パッケージ追加時の判断基準(軽量なものを優先する等)