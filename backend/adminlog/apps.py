from django.apps import AppConfig


class AdminlogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'adminlog'
    def ready(self):
        # 管理ログモデルの差し替えを明示する
        from django.contrib import admin
        from adminlog.models import LogEntry
        admin.models.LogEntry = LogEntry
