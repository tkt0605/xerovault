#!/bin/bash
set -e
# ========= Backendリソースの起動SHELL　========
# ========= 基本設定 =========

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env.production"

if [ -f "$ENV_PATH" ]; then
  echo "📦 Loading environment variables from $ENV_PATH..."
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    value="${value%%#*}"
    export "$key"="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  done < "$ENV_PATH"
else
  echo "❌ .env.production file not found at $ENV_PATH. Aborting."
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