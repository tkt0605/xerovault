#!/bin/bash
set -e
# ========= 起動中リソースの停止SHELL　========
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
#
echo "🚫 WebAppを停止中..."
az webapp stop --name ${BACKEND_APP} --resource-group ${RG_NAME} 
#
echo "🚫 Postgres Flexible Serverを停止中..."
az postgres flexible-server stop --name ${PG_NAME} --resource-group ${RG_NAME}

echo "👌 全リソースの停止完了。"