#!/bin/bash

set -e  # エラーで即終了

# ========= リソースの起動・作成SHELL　========
# ======== .env を読み込み ========

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env.production"
echo "📦 Loading environment variables from $ENV_PATH..."

# 手動で読み込んでみる
set -a
source "$ENV_PATH"
set +a

az group delete --name xerovault-rg-v1 --yes --no-wait
echo "🗑️ Resource Group deletion initiated."