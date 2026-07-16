# Xero Vault

グループを作り、メンバーで目標(Goal)を設定し、達成をYES/NO投票で承認し合うことでスコア・継続ストリークを競うゴール管理アプリ。詳しいコンセプトは [docs/vision.md](docs/vision.md)、ドメインモデルは [docs/domain-model.md](docs/domain-model.md) を参照。

## 構成(pnpm workspaces モノレポ)

- `frontend/` – Vue 3 + Vite SPA。Pinia でステート管理、Tailwind CSS でスタイリング。データ・認証は Supabase(`@supabase/supabase-js`)に直接アクセスする。
- `packages/shared/` – zod スキーマ・API型定義(`@xerovault/shared`)。フロントのフォームバリデーション・型として使用。
- `supabase/migrations/` – Postgresスキーマ・RLSポリシー・RPC関数(スコア計算・投票処理など、旧Expressバックエンドが担っていたロジック)。
- `docker-compose.yml` – frontend を起動する開発環境(DB・APIサーバーはSupabaseが提供するため不要)。

## セットアップ

1. [Supabase](https://supabase.com/)でプロジェクトを作成し、Authentication > Providers で Email と Google を有効化する(Google側はGoogle Cloud ConsoleでOAuthクライアントを作成し、Client ID/SecretをSupabaseに設定)。
2. Supabaseダッシュボードの SQL Editor で `supabase/migrations/0001_init.sql` の内容を貼り付けて実行する(スキーマ・RLS・RPC関数が作成される)。
3. `.env.example` を `.env` にコピーし、SupabaseのProject URL・anon keyを埋める。
4. 以下を実行してフロントエンドを起動する。

   ```bash
   docker compose up --build
   ```

ローカルでNode.js側のツール(lint/build)だけ動かす場合は [pnpm](https://pnpm.io/) をインストールし、リポジトリルートで `pnpm install` する。

## アクセス

- **Frontend**: [http://localhost:5173](http://localhost:5173) – Vite dev server

## 主要ドメイン

- **User(profiles)** – アカウント。複数の Group に所属できる。`auth.users`作成時にトリガーで自動作成される。
- **Group** – 目標を共有するチーム。スコア・ストリークを保持。
- **Goal** – Group 内で設定する目標。担当者(assignee)を割り当てられる。
- **GoalVote / Vote** – Goal の達成可否をメンバーが YES/NO で投票し承認する仕組み。
- **Message** – Goal に紐づくコメント。
