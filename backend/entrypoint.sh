#!/bin/bash

# 適切な wait-for-db ロジックも入れると安定します
python manage.py migrate --noinput
python manage.py collectstatic --noinput
exec gunicorn backend.wsgi:application --bind 0.0.0.0:8000
