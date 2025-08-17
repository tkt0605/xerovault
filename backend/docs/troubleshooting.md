# Troubleshooting (XeroVault)

このドキュメントは、XeroVault の開発/運用で遭遇しやすいエラーと、最短の復旧手順をまとめたものです。  
サービス名の例は `xero-backend`（Django）と `xero-db`（PostgreSQL）を想定しています。

---

## 目次
1. [ModuleNotFoundError: services](#1-modulenotfounderror-services)
2. [Apps aren't loaded yet.](#2-apps-arent-loaded-yet)
3. [PYTHONPATH が空](#3-pythonpath-が空)
4. [pg_trgm / gin_trgm_ops が無い](#4-pg_trgm--gin_trgm_ops-が無い)
5. [インデックス名の重複 (models.E030)](#5-インデックス名の重複-modelse030)
6. [マイグレーションの依存ねじれ / 循環 / 履歴不整合](#6-マイグレーションの依存ねじれ--循環--履歴不整合)
7. [便利コマンド](#7-便利コマンド)

---

## 1) ModuleNotFoundError: services
**症状**  
`ModuleNotFoundError: No module named 'services'`

**原因**  
実体が `/backend/api/services`（アプリ配下）なのに、`from services...` としていた / パス設定不整合。

**対処（推奨）** 相対インポートに修正
```python
# api/views.py など
from .services.search import GlobalSearchEngine, SearchMode
```
**代替**: 絶対インポート  
```python
from api.services.search import GlobalSearchEngine, SearchMode
```

**注意**: `services/` に `__init__.py` を置く（空でもOK）。

---

## 2) Apps aren't loaded yet.
**症状**  
`django.core.exceptions.AppRegistryNotReady: Apps aren't loaded yet.`

**原因**  
Django 未初期化 (`django.setup()`) のまま `api.models` を import。`python -c` ワンライナー等で起きやすい。

**対処**  
```bash
docker compose exec -T xero-backend bash -lc 'python - <<PY
import os, django, importlib
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()
importlib.import_module("api.services.search")
print("OK: api.services.search")
PY'
```
**設計メモ**: 重い依存（models import）は関数内で**遅延インポート**にすると安全。
```python
def run_search(...):
    from api.models import GenerateGroup, GenerateLibrary
    ...
```

---

## 3) PYTHONPATH が空
**症状**  
`PYTHONPATH=None` / `sys.path` に `/backend` が無く import 失敗。Compose で `WARN The "PYTHONPATH" variable is not set` など。

**対処（compose 例）**
```yaml
services:
  xero-backend:
    environment:
      DJANGO_SETTINGS_MODULE: "config.settings"
      PYTHONPATH: "/backend"         # 余計な参照は付けない
    working_dir: /backend
```
**確認**
```bash
docker compose exec -T xero-backend python - <<'PY'
import os, sys
print("PYTHONPATH =", os.environ.get("PYTHONPATH"))
print("sys.path[:5] =", sys.path[:5])
PY
```

---

## 4) pg_trgm / gin_trgm_ops が無い
**症状**  
`django.db.utils.ProgrammingError: operator class "gin_trgm_ops" does not exist for access method "gin"`

**原因**  
`pg_trgm` 拡張が未導入のDBで trgm用 GIN インデックスを作成しようとした。

**対処（DBに拡張を導入・冪等）**
```bash
docker compose exec -T xero-db bash -lc 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"'

docker compose exec -T xero-db bash -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dx"'
```

**Django マイグレーションで拡張を管理（推奨）**
```python
# api/migrations/0020_enable_pg_trgm.py
from django.db import migrations
from django.contrib.postgres.operations import CreateExtension

class Migration(migrations.Migration):
    dependencies = [('api','0018_remove_goal_progress')]
    operations = [CreateExtension('pg_trgm')]
```
**インデックス側は拡張に依存**
```python
dependencies = [
    ('api','0018_remove_goal_progress'),
    ('api','0020_enable_pg_trgm'),
]
```

---

## 5) インデックス名の重複 (models.E030)
**症状**  
`models.E030 index name 'xxx' is not unique among models`

**対処**  
アプリ内で一意な名前にする。例：
```
idx_generategroup_name_trgm
idx_generategroup_tag_trgm
idx_generatelibrary_name_trgm
idx_generatelibrary_tag_trgm
```
`GinIndex(opclasses=["gin_trgm_ops"])` を使用。

---

## 6) マイグレーションの依存ねじれ / 循環 / 履歴不整合
**例1**: `CircularDependencyError`  
**例2**: `InconsistentMigrationHistory: Migration api.0019... is applied before its dependency api.0020_enable_pg_trgm`

**原則**
- 依存は「**拡張 → インデックス**」の順。番号より **dependencies** が優先。
- 既に適用済みの依存を**後から書き換えない**。必要なら新マイグレーションで調整。

**解決A（おすすめ）: 履歴を整える（fake適用）**
```bash
# 拡張をDBに導入（冪等）
docker compose exec -T xero-db bash -lc 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"'

# 0020 を適用済みとして記録
docker compose exec -T xero-backend python manage.py migrate api 0020_enable_pg_trgm --fake

# 残りを実行
docker compose exec -T xero-backend python manage.py migrate
```

**解決B: ロールバック → 正順で適用**
```bash
docker compose exec -T xero-backend python manage.py migrate api 0018
docker compose exec -T xero-backend python manage.py migrate api 0020_enable_pg_trgm
docker compose exec -T xero-backend python manage.py migrate
```

**最終手段（歴史矛盾で migrate が走らない時）**: `django_migrations` に安全INSERT
```bash
docker compose exec -T xero-db bash -lc 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"    -c "INSERT INTO django_migrations(app,name,applied)
       SELECT '''api''','''0020_enable_pg_trgm''', NOW()
       WHERE NOT EXISTS (
         SELECT 1 FROM django_migrations WHERE app='''api''' AND name='''0020_enable_pg_trgm''' );"'
```

---

## 7) 便利コマンド
**Django が接続している DB の確認**
```bash
docker compose exec -T xero-backend python - <<'PY'
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE","config.settings")
django.setup()
from django.conf import settings
print(settings.DATABASES["default"])
PY
```

**PowerShell / TTY 罠の回避（STDIN 渡し）**
```bash
# Linux/macOS
docker compose exec -T xero-backend python - <<'PY'
print("stdin ok")
PY

# Windows PowerShell
docker compose exec xero-backend python -c 'print("stdin ok")'
```

---

### 付録: 検索エンジン設計メモ
- `basic`: `icontains`  
- `fuzzy`: `pg_trgm` + しきい値 & GIN インデックス  
- `fts`: `SearchVector/SearchQuery/SearchRank` + GIN（必要なら日本語辞書や pgroonga の検討）

---

**更新履歴**
- 2025-08-17: 初版作成
