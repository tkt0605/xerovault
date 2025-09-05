#!/bin/bash
set -e
# ========= 起動中リソースの停止SHELL　========
# ========= 基本設定 =========

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env.production"
echo "📦 Loading environment variables from $ENV_PATH..."

# 手動で読み込んでみる
set -a
source "$ENV_PATH"
set +a

#
echo "🚫 WebAppを停止中..."
az webapp stop --name $BACKEND_APP --resource-group $RG_NAME 
#
echo "🚫 Postgres Flexible Serverを停止中..."
az postgres flexible-server stop --name $PG_NAME --resource-group $RG_NAME

echo "👌 全リソースの停止完了。"