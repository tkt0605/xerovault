#!/bin/bash

set -e  # エラーで即終了

# ======== .env を読み込み ========
if [ -f .env ]; then
  echo "📦 Loading environment variables from .env..."
  while IFS='=' read -r key value; do
    # 空行やコメント行をスキップ
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    # 行末コメント除去（=の後に # がある場合に対応）
    value="${value%%#*}"
    export "$key=$(echo "$value" | xargs)"  # 前後の空白除去
  done < .env
else
  echo "❌ .env file not found. Aborting."
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
  --admin-user $PG_ADMIN \
  --admin-password $PG_PASS \
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
  --docker-custom-image-name $DOCKER_IMAGE \
  --docker-registry-server-url https://ghcr.io \
  --docker-registry-server-user tkt0605 \
  --docker-registry-server-password $GITHUB_PAT

# ======== WebApp 環境変数（App Settings） ========
echo "🔐 Setting environment variables..."
az webapp config appsettings set \
  --resource-group $RG_NAME \
  --name $BACKEND_APP \
  --settings \
  DJANGO_DEBUG=false \
  DJANGO_ALLOWED_HOSTS="${BACKEND_APP}.azurewebsites.net" \
  DATABASE_URL="postgresql://${PG_ADMIN}:${PG_PASS}@${PG_NAME}.postgres.database.azure.com:5432/${PG_DB}?sslmode=require" \
  SECRET_KEY="$SECRET_KEY" \
  SECURE_SSL_REDIRECT=true \
  LOG_LEVEL=INFO

# ======== Static Web App (Nuxt Frontend) 作成 ========
echo "🎨 Creating Static Web App (Nuxt frontend)..."
az staticwebapp create \
  --name $FRONTEND_APP \
  --resource-group $RG_NAME \
  --source $GITHUB_REPOSITORY \
  --location $LOCATION_STATIC \
  --branch main \
  --app-location "frontend/xerofront/" \
  --output-location ".output/public" \
  --token $GITHUB_PAT

echo "✅ All Azure resources have been created successfully!"
