#!/bin/bash
set -e
# ========= 停止リソースの再起動SHELL　========
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

echo "🪛 PostgreSQL Felxible Serverを再起動中..."
az postgres flexible-server start \
  --name $PG_NAME \
  --resource-group $RG_NAME

echo "Dockerイメージ走らせてます……"
az webapp config container set \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME} \
  --container-image-name ghcr.io/tkt0605/xerovault-backend:v1.1.17 \
  --container-registry-url https://ghcr.io \
  --container-registry-user tkt0605 \
  # --container-registry-password "$GITHUB_PAT"

az webapp config appsettings set \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME} \
  --settings \
  PORT=8000\
  WEBSITES_PORT=8000\
  STARTUP_COMMAND="/backend/scripts/docker-cmd"\
  # DOCKER_REGISTRY_SERVER_PASSWORD="$GITHUB_PAT"
echo "✅ Dockerイメージ起動・完了!"


echo "🛠️ Web Appを再起動中..."
az webapp start \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME}


echo "👌 停止中のリソースらを再起動・完了!!"

az webapp log tail \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME}