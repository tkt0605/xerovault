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
