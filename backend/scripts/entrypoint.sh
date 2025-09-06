#!/bin/bash
set -e

# AzureがPORTをセットしてない場合は8000を使う


# DBマイグレーション
python manage.py migrate --noinput

# 静的ファイル収集
python manage.py collectstatic --noinput

# Gunicorn起動
exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120
