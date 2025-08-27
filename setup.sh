#!/bin/bash

# ========= 基本設定 =========
RG_NAME="xerovault-rg"
LOCATION="japaneast"
LOCATION_STATIC="eastasia"
PG_NAME="xerovaultpg6483"
PG_ADMIN="takato"
PG_PASS="StrongPass123"     # ← 実際は .env に入れること！
PG_DB="xerovault_db"
BACKEND_APP="xerovault-api"
FRONTEND_APP="xerovault-frontend"
DOCKER_IMAGE="ghcr.io/username/xerovault-backend:latest"
PLAN_NAME="xerovault-plan"
SECRET_KEY="django-insecure-&i4%yfpcf=k)z-8cx3o=1+1&3wwtc0y+pgxboev_ymq*@p@o^!"
GITHUB_REPOSITORY="https://github.com/tkt0605/xerovault"
ALLOWED_ORIGINS="https://gray-mushroom-0eb277800.1.azurestaticapps.net"

# =========  MICROSOFT.WEB作成コマンド　=========

echo "Checking Microsoft.Web resource provider registration..."

REG_STATE=$(az provider show --namespace Microsoft.Web --query "registrationState" -o tsv)

if [[ "$REG_STATE" != "Registered" ]]; then
  echo "Microsoft.Web is not registered. Registering now..."
  az provider register --namespace Microsoft.Web
  echo "Waiting for Microsoft.Web to register..."
  # 簡易待機（5秒×最大6回 = 最大30秒）
  for i in {1..6}; do
    sleep 5
    REG_STATE=$(az provider show --namespace Microsoft.Web --query "registrationState" -o tsv)
    echo "Current state: $REG_STATE"
    if [[ "$REG_STATE" == "Registered" ]]; then
      echo "Microsoft.Web successfully registered!"
      break
    fi
  done
else
  echo "Microsoft.Web is already registered."
fi

# ========= リソース・グループの作成　=========
az group create \
  --name ${RG_NAME} \
  --location ${LOCATION}

# =========　Postgresql Flexible Serverの作成　=========
az postgres flexible-server create \
  --resource-group ${RG_NAME} \
  --location ${LOCATION} \
  --name ${PG_NAME} \
  --admin-user ${PG_ADMIN} \
  --admin-password ${PG_PASS} \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 14 \
  --public-access All \
  --yes

# ========= DB作成 =========
az postgres flexible-server db create \
  --resource-group ${RG_NAME} \
  --server-name ${PG_NAME} \
  --database-name ${PG_DB} \

# ========= App Service Plan 作成 =========
az appservice plan create \
  --name ${PLAN_NAME} \
  --resource-group ${RG_NAME} \
  --sku B1 \
  --is-linux

# ========= WebApp作成 =========
az webapp create \
  --resource-group ${RG_NAME} \
  --plan ${PLAN_NAME} \
  --name ${BACKEND_APP} \
  --deployment-container-image-name ${DOCKER_IMAGE}

# ========= Nuxt用 Static Web App 作成（Optional） =========
az staticwebapp create \
  --name ${FRONTEND_APP} \
  --resource-group ${RG_NAME} \
  --source ${GITHUB_REPOSITORY} \
  --location ${LOCATION_STATIC} \
  --branch main \
  --app-location "frontend/xerofront/" \
  --output-location ".output/public" \
  --login-with-github

echo "✅ Azure resource setup completed successfully!"