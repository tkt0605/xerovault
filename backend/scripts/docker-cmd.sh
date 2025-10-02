#!/bin/bash
set -e
# ========= 環境変数 =========
export RUN_SUPERUSER=1
export RUN_MIGRATIONS=1
export RUN_MODE="app"  # ← sleep にしたい場合は "sleep" にする

echo "🧪 環境変数チェック:"
echo "  RUN_SUPERUSER=$RUN_SUPERUSER"
echo "  RUN_MIGRATIONS=$RUN_MIGRATIONS"
echo "  RUN_MODE=$RUN_MODE"

# ========= SSHD をバックグラウンドで起動 =========
/usr/sbin/sshd &

# ========= マイグレーションと collectstatic =========
if [ "$RUN_MIGRATIONS" = "1" ]; then
  echo "⚙️ Running migrations..."
  python manage.py migrate
  python manage.py collectstatic --noinput
else
  echo "✅ Skipping migrations."
fi

# ========= スーパーユーザー作成（既存チェック付き） =========
if [ "$RUN_SUPERUSER" = "1" ]; then
  echo "🛠️ Creating superuser (if not exists)..."
  python scripts/superuser.py
fi

# ========= アプリ起動 =========
if [ "$RUN_MODE" = "sleep" ]; then
  echo "🛌 RUN_MODE=sleep: 無限待機中..."
  sleep infinity
else
  echo "🚀 RUN_MODE=app: Gunicorn 起動中..."
  exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --timeout 120 --workers 3
fi
