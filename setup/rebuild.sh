#!/bin/bash
set -e
# ========= 停止リソースの再起動SHELL　========
# ========= 基本設定 =========

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env.production"
echo "📦 Loading environment variables from $ENV_PATH..."

# 手動で読み込んでみる
set -a
source "$ENV_PATH"
set +a

# echo "🪛 PostgreSQL Felxible Serverを再起動中..."
# az postgres flexible-server start \
#   --name $PG_NAME \
#   --resource-group $RG_NAME

echo "Dockerイメージ走らせてます……"
az webapp config container set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --container-image-name $DOCKER_IMAGE \
  --container-registry-url https://ghcr.io \
  --container-registry-user tkt0605 \
  --container-registry-password $GITHUB_PAT

az webapp config appsettings set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --settings \
  PORT=$PORT \
  WEBSITES_PORT=$WEBSITES_PORT \
  # STARTUP_COMMAND="/backend/scripts/docker-cmd"
echo "✅ Dockerイメージ起動・完了!"


echo "🛠️ Web Appを再起動中..."
az webapp start \
  --name $BACKEND_APP \
  --resource-group $RG_NAME


echo "👌 停止中のリソースらを再起動・完了!!"

az webapp log tail \
  --name $BACKEND_APP \
  --resource-group $RG_NAME