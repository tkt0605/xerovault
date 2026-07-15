# Xero Vault

グループを作り、メンバーで目標(Goal)を設定し、達成をYES/NO投票で承認し合うことでスコア・継続ストリークを競うゴール管理アプリ。詳しいコンセプトは [docs/vision.md](docs/vision.md)、ドメインモデルは [docs/domain-model.md](docs/domain-model.md) を参照。

## 構成(pnpm workspaces モノレポ)

- `backend/` – Express + TypeScript API。Prisma ORM + PostgreSQL。
- `frontend/` – Vue 3 + Vite SPA。Pinia でステート管理、Tailwind CSS でスタイリング。
- `packages/shared/` – backend/frontend で共有する zod スキーマ・API型定義(`@xerovault/shared`)。
- `docker-compose.yml` – Postgres・backend・frontend をまとめて起動する開発環境。

## セットアップ

1. `.env.example` を `.env` にコピーし、値を埋める。
2. 以下を実行してスタックを起動する。

   ```bash
   docker compose up --build
   ```

   backend コンテナ起動時に `prisma migrate deploy` が自動実行される。

ローカルでNode.js側のツール(lint/test/build)だけ動かす場合は [pnpm](https://pnpm.io/) をインストールし、リポジトリルートで `pnpm install` する。

## アクセス

- **Frontend**: [http://localhost:5173](http://localhost:5173) – Vite dev server
- **Backend API**: [http://localhost:8000](http://localhost:8000) – Express server

## 主要ドメイン

- **User** – アカウント。複数の Group に所属できる。
- **Group** – 目標を共有するチーム。スコア・クレジット・ストリークを保持。
- **Goal** – Group 内で設定する目標。担当者(assignee)を割り当てられる。
- **GoalVote / Vote** – Goal の達成可否をメンバーが YES/NO で投票し承認する仕組み。
- **Message** – Goal に紐づくコメント。
