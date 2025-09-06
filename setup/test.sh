#!/bin/bash

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env.production"
echo "📦 Loading environment variables from $ENV_PATH..."

# 手動で読み込む
set -a
source "$ENV_PATH"
set +a

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
az webapp log tail \
  --name xerovault-api-v2 \
  --resource-group xerovault-rg-v2