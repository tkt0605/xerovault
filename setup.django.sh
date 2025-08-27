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

# ========= 環境変数の設定（Djangoの設定） =========
az webapp config appsettings set \
  --name ${BACKEND_APP} \
  --resource-group ${RG_NAME} \
  --settings DJANGO_SECRET_KEY=${SECRET_KEY} \
             DJANGO_ALLOWED_HOSTS=${BACKEND_APP}.azurewebsites.net \
             DATABASE_URL="postgres://${PG_ADMIN}:${PG_PASS}@${PG_NAME}.postgres.database.azure.com:5432/${PG_DB}" \
             CORS_ALLOWED_ORIGINS=${ALLOWED_ORIGINS}