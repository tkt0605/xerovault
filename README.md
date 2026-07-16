# Xero Vault

グループを作り、メンバーで目標(Goal)を設定し、達成をYES/NO投票で承認し合うことでスコア・継続ストリークを競うゴール管理アプリ。詳しいコンセプトは [docs/vision.md](docs/vision.md)、ドメインモデルは [docs/domain-model.md](docs/domain-model.md) を参照。

## 構成(pnpm workspaces モノレポ)

- `frontend/` – Vue 3 + Vite SPA。Pinia でステート管理、Tailwind CSS でスタイリング。データ・認証は Supabase(`@supabase/supabase-js`)に直接アクセスする。
- `packages/shared/` – zod スキーマ・API型定義(`@xerovault/shared`)。フロントのフォームバリデーション・型として使用。
- `supabase/migrations/` – Postgresスキーマ・RLSポリシー・RPC関数(スコア計算・投票処理など、旧Expressバックエンドが担っていたロジック)。
- `supabase/functions/notify-digest/` – 投票待ち・締切接近・期限切れをまとめてメール通知するEdge Function(pg_cron + pg_netから毎日1回呼び出される)。
- `supabase/functions/unsubscribe/` – ダイジェストメール本文のリンクから、ログイン不要でワンタップ配信停止するためのEdge Function。
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

## 通知(投票待ち・締切接近・期限切れ)のセットアップ

`0006_notification_digest.sql`・`0008_notification_preferences.sql` を適用しただけでは動かず、以下の手動セットアップが必要(Supabase CLIが必要)。

1. [Resend](https://resend.com/)でAPIキーを発行し、送信元ドメインを認証する。
2. Edge Functionのシークレットを設定する。

   ```bash
   supabase secrets set RESEND_API_KEY=re_xxxxx NOTIFY_FROM_EMAIL="Xerovault <notify@yourdomain.com>"
   ```

3. Edge Functionをデプロイする(notify-digestとunsubscribeの2つ)。

   ```bash
   supabase functions deploy notify-digest --project-ref <project-ref>
   supabase functions deploy unsubscribe --project-ref <project-ref>
   ```

4. SQL EditorでSupabase VaultにEdge FunctionのURLとservice_role keyを登録する(このリポジトリには実値を含めない)。

   ```sql
   select vault.create_secret('https://<project-ref>.functions.supabase.co/notify-digest', 'notify_digest_url');
   select vault.create_secret('<service_role key>', 'notify_digest_service_role_key');
   ```

登録後は `0008_notification_preferences.sql` で設定した pg_cron ジョブ(`notify-digest`, 毎日 UTC 10:00 = JST 19:00)が自動でEdge Functionを叩く。`select * from cron.job_run_details order by start_time desc limit 5;` で実行結果を確認できる。

配信停止(unsubscribe)自体はSupabase Vaultの設定不要で動く(メール内リンクから直接叩かれるだけ)。デプロイさえしておけば良い。

## アクセス

- **Frontend**: [http://localhost:5173](http://localhost:5173) – Vite dev server

## 主要ドメイン

- **User(profiles)** – アカウント。複数の Group に所属できる。`auth.users`作成時にトリガーで自動作成される。
- **Group** – 目標を共有するチーム。スコア・ストリークを保持。
- **Goal** – Group 内で設定する目標。担当者(assignee)を割り当てられる。
- **GoalVote / Vote** – Goal の達成可否をメンバーが YES/NO で投票し承認する仕組み。
- **Message** – Goal に紐づくコメント。
