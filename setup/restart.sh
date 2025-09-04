#!/bin/bash
set -e
# ========= Backendデバック用のリスタートHELL　========
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
echo "🛠️ Configuring container image..."
az webapp config container set \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME} \
  --container-image-name ghcr.io/tkt0605/xerovault-backend:v1.1.17. \
  --container-registry-url https://ghcr.io \
  --container-registry-user tkt0605 \
  # --container-registry-password "$GITHUB_PAT"

echo "⚙️ Setting PORT..."
az webapp config appsettings set \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME} \
  --settings \
   PORT=8000 \
   WEBSITES_PORT=8000 \
   STARTUP_COMMAND="/backend/scripts/docker-cmd"\
  #  DOCKER_REGISTRY_SERVER_PASSWORD="$GITHUB_PAT"

echo "🔁 Restarting webapp..."
az webapp start \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME}

echo "🔍 Confirming current container image..."
az webapp config container show \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME} \
  --query "containerImageName"

echo "📡 Tail logs (Ctrl+C to stop)..."
az webapp log tail \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME}