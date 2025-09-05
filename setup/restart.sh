#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/../.env.production"
echo "📦 Loading environment variables from $ENV_PATH..."
set -a
source "$ENV_PATH"
set +a

echo "🧪 環境変数チェック:"
echo "  GITHUB_PAT=$GITHUB_PAT"
echo "  BACKEND_APP=$BACKEND_APP"
echo "  RG_NAME=$RG_NAME"

echo "🛠️ Configuring container image..."
az webapp config container set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --container-image-name $DOCKER_IMAGE \
  --container-registry-url https://ghcr.io \
  --container-registry-user tkt0605 \
  --container-registry-password "$GITHUB_PAT"

echo "⚙️ Setting PORT..."
az webapp config appsettings set \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --settings \
  PORT="$PORT" \
  WEBSITES_PORT="$WEBSITES_PORT" \
  STARTUP_COMMAND="/backend/scripts/docker-cmd"\
  DJANGO_DEBUG=false \
  DJANGO_ALLOWED_HOSTS="${BACKEND_APP}.azurewebsites.net" \
  DATABASE_URL="postgresql://${PG_USER}:${PG_PASSWORD}@${PG_NAME}.postgres.database.azure.com:5432/${PG_DB}?sslmode=require" \
  SECRET_KEY="$DJANGO_SECRET_KEY" \
  SECURE_SSL_REDIRECT=true \
  LOG_LEVEL=INFO \
  CORS_ALLOWED_ORIGINS="$CORS_ALLOWED_ORIGINS"
  

echo "🔁 Restarting webapp..."
az webapp restart \
  --name $BACKEND_APP \
  --resource-group $RG_NAME
echo "🔍 Confirming current container image..."
az webapp config container show \
  --name $BACKEND_APP \
  --resource-group $RG_NAME\
  --query "properties.[imageName,registryUrl]" \
  --output table

echo "📡 Tail logs (Ctrl+C to stop)..."
  az webapp log tail \
  --name $BACKEND_APP \
  --resource-group $RG_NAME