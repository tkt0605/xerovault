#!/bin/bash
set -e
az postgres flexible-server firewall-rule create \
  --name xerovaultpg \
  --resource-group xerovault-rg-v2 \
  --rule-name allow-local \
  --start-ip-address 175.132.130.46 \
  --end-ip-address 175.132.130.46