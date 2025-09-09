#!/bin/bash
set -euo pipefail

ENV_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env.production"

if [ -f "$ENV_PATH" ]; then
  echo "📦 Loading environment variables from $ENV_PATH..."

  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # コメント行や空行を無視
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

    # valueの右側にある # コメントを削除
    value="${value%%#*}"
    value="${value%%[[:cntrl:]]}"      # 制御文字も削除
    value="${value%"${value##*[![:space:]]}"}" # 末尾スペース削除
    value="${value#\"}"                # 先頭の " を削除
    value="${value%\"}"                # 末尾の " を削除

    export "$key=$value"
  done < "$ENV_PATH"
else
  echo "❌ .env.production not found at $ENV_PATH"
  exit 1
fi

echo "🧪 環境変数チェック:"
echo "  RG_NAME=$RG_NAME"
echo "  LOCATION=$LOCATION"
echo "  PLAN_NAME=$PLAN_NAME"
echo "  PG_NAME=$PG_NAME"
echo "  PG_USER=$PG_USER"
echo "  PG_PASSWORD=$PG_PASSWORD"
echo "  PG_DB=$PG_DB"
echo "  BACKEND_APP=$BACKEND_APP"
echo "  DOCKER_IMAGE=$DOCKER_IMAGE"
echo "  GITHUB_PAT=$GITHUB_PAT"
echo "  FRONTEND_APP=$FRONTEND_APP"
echo "  GITHUB_REPOSITORY=$GITHUB_REPOSITORY"
echo "  GITHUB_BRANCH=$GITHUB_BRANCH"
echo "  DJANGO_SECRET_KEY=$DJANGO_SECRET_KEY"
echo "  CORS_ALLOWED_ORIGINS=$CORS_ALLOWED_ORIGINS"
echo "  PORT=$PORT"
echo "  WEBSITES_PORT=$WEBSITES_PORT"
echo "  GITHUB_USERNAME=$GITHUB_USERNAME"

