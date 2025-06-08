from django.apps import AppConfig
from django.apps import apps

class AdminlogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'adminlog'
    def ready(self):
        # 管理ログモデルの差し替えを明示する
        from django.contrib import admin
        from adminlog.models import LogEntry
        admin.models.LogEntry = LogEntry
        CustomUser = apps.get_model('api', 'CustomUser')
        CustomUser.objects.count()
