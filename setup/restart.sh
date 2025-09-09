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
echo   GITHUB_PAT=$GITHUB_PAT
echo   BACKEND_APP=$BACKEND_APP
echo   RG_NAME=$RG_NAME

echo "🛠️ Configuring container image..."
az webapp config container set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --container-image-name $DOCKER_IMAGE \
  --container-registry-url $GITHUB_URL \
  --container-registry-user $GITHUB_USERNAME \
  --container-registry-password "${GITHUB_PAT}"

echo "⚙️ Setting PORT..."
az webapp config appsettings set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --settings \
  PORT=$PORT \
  WEBSITES_PORT=$WEBSITES_PORT \
  DJANGO_DEBUG=false \
  DJANGO_ALLOWED_HOSTS="${BACKEND_APP}.azurewebsites.net" \
  DATABASE_URL="postgresql://${PG_USER}:${PG_PASSWORD}@${PG_NAME}.postgres.database.azure.com:5432/${PG_DB}?sslmode=require" \
  SECRET_KEY="$DJANGO_SECRET_KEY" \
  SECURE_SSL_REDIRECT=true \
  LOG_LEVEL=INFO \
  CORS_ALLOWED_ORIGINS="$CORS_ALLOWED_ORIGINS"
  
az webapp config set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME 

echo "🔁 Restarting webapp..."
az webapp restart \
  --name $BACKEND_APP \
  --resource-group $RG_NAME

echo "🔍 Confirming current container image..."
az webapp config container show \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --output json


echo "📡 Tail logs (Ctrl+C to stop)..."
  az webapp log tail \
  --name $BACKEND_APP \
  --resource-group $RG_NAME