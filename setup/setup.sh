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
# ======== Microsoft.Web の登録確認 ========
echo "🌐 Checking Microsoft.Web resource provider..."
REG_STATE=$(az provider show --namespace Microsoft.Web --query "registrationState" -o tsv)
if [[ "$REG_STATE" != "Registered" ]]; then
  echo "⏳ Registering Microsoft.Web..."
  az provider register --namespace Microsoft.Web
  for i in {1..10}; do
    sleep 5
    REG_STATE=$(az provider show --namespace Microsoft.Web --query "registrationState" -o tsv)
    echo "Current state: $REG_STATE"
    if [[ "$REG_STATE" == "Registered" ]]; then break; fi
  done
fi
echo "✅ Microsoft.Web is registered."

# ======== リソースグループ作成 ========
echo "🧱 Creating resource group..."
az group create --name $RG_NAME --location $LOCATION

# ======== PostgreSQL Flexible Server ========
echo "🐘 Creating PostgreSQL flexible server..."
az postgres flexible-server create \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --name $PG_NAME \
  --admin-user $PG_USER \
  --admin-password $PG_PASSWORD \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 14 \
  --public-access All \
  --yes

# ======== PostgreSQL Database 作成 ========
echo "📘 Creating database $PG_DB..."
az postgres flexible-server db create \
  --resource-group $RG_NAME \
  --server-name $PG_NAME \
  --database-name $PG_DB

# ======== App Service Plan（存在チェック付き） ========
if ! az appservice plan show -g "$RG_NAME" -n "$PLAN_NAME" >/dev/null 2>&1; then
  echo "⚙️ Creating App Service Plan..."
  az appservice plan create \
    --name $PLAN_NAME \
    --resource-group $RG_NAME \
    --sku B1 \
    --is-linux
else
  echo "✅ App Service Plan already exists."
fi

# ======== WebApp for Containers 作成 ========
echo "🚀 Creating WebApp..."
az webapp create \
  --resource-group $RG_NAME \
  --plan $PLAN_NAME \
  --name $BACKEND_APP \
  --runtime "PYTHON:3.11"

# ======== コンテナイメージ設定 ========
echo "🛠️ Configuring container image..."
az webapp config container set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --container-image-name $DOCKER_IMAGE \
  --container-registry-url https://ghcr.io \
  --container-registry-user tkt0605 \
  --container-registry-password $GITHUB_PAT

# ========= 環境変数の設定（Djangoの設定） =========
az webapp config appsettings set \
  --name "$BACKEND_APP" \
  --resource-group "$RG_NAME" \
  --settings \
  PORT=$PORT \
  WEBSITES_PORT=$WEBSITES_PORT \
  DJANGO_DEBUG=false \
  DJANGO_ALLOWED_HOSTS="${BACKEND_APP}.azurewebsites.net" \
  DATABASE_URL="postgresql://${PG_USER}:${PG_PASSWORD}@${PG_NAME}.postgres.database.azure.com:5432/${PG_DB}?sslmode=require" \
  SECRET_KEY="$DJANGO_SECRET_KEY" \
  SECURE_SSL_REDIRECT=true \
  LOG_LEVEL=INFO \
  CORS_ALLOWED_ORIGINS="$CORS_ALLOWED_ORIGINS"

# # ======== Static Web App (Nuxt Frontend) 作成 ========
echo "🎨 Creating Static Web App (Nuxt frontend)..."
az staticwebapp create \
  --name "$FRONTEND_APP" \
  --resource-group "$RG_NAME" \
  --source "$GITHUB_REPOSITORY" \
  --location "$LOCATION_STATIC" \
  --branch  "$GITHUB_BRANCH"\
  --app-location "frontend/xerofront/" \
  --output-location "frontend/xerovault/.output/public" \
  --login-with-github \
  --token "${GITHUB_PAT}"


echo "✅ All Azure resources have been created successfully!"
 