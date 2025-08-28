#!/bin/bash
set -e
# ========= 基本設定 =========
if [ -f .env ]; then
  echo "📦 Loading environment variables from .env..."
  while IFS='=' read -r key value; do
    # 空行やコメント行をスキップ
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    # 行末コメント除去（=の後に # がある場合に対応）
    value="${value%%#*}"
    export "$key=$(echo "$value" | xargs)"  # 前後の空白除去
  done < .env
else
  echo "❌ .env file not found. Aborting."
  exit 1
fi
# ========= 環境変数の設定（Djangoの設定） =========
az webapp config appsettings set \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME} \
  --settings DJANGO_SECRET_KEY=${SECRET_KEY} \
             DJANGO_ALLOWED_HOSTS=${BACKEND_APP}.azurewebsites.net \
             DATABASE_URL="postgres://${PG_ADMIN}:${PG_PASS}@${PG_NAME}.postgres.database.azure.com:5432/${PG_DB}" \
             CORS_ALLOWED_ORIGINS=${ALLOWED_ORIGINS}