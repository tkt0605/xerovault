#!/bin/bash
set -e
# ========= Backendリソースの起動SHELL　========
# ========= 基本設定 =========

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env.production"
echo "📦 Loading environment variables from $ENV_PATH..."

# 手動で読み込んでみる
set -a
source "$ENV_PATH"
set +a

echo "✅ PAT: $GITHUB_PAT"
# 確認
echo "PAT: ${GITHUB_PAT}"
az webapp config appsettings delete \
  --name "$BACKEND_APP" \
  --resource-group "$RG_NAME" \
  --setting-names \
    DOCKER_REGISTRY_SERVER_URL \
    DOCKER_REGISTRY_SERVER_USERNAME \
    DOCKER_REGISTRY_SERVER_PASSWORD \
    DOCKER_CUSTOM_IMAGE_NAME


az webapp config container set \
  --name "$BACKEND_APP" \
  --resource-group "$RG_NAME" \
  --container-image-name "$DOCKER_IMAGE" \
  --container-registry-url "https://ghcr.io" \
  --container-registry-user "tkt0605" \
  --container-registry-password $GITHUB_PAT
