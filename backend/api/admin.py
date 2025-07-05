from django.contrib import admin
from .models import CustomUser, GenerateGroup, GeneratePublicToken, Goal
from django.contrib.auth.admin import UserAdmin as baseUserAdmin
from api.model.custom_token import CustomOutStandingToken, CustomBlackListToken
class CustomUserAdmin(baseUserAdmin):
    list_display = ['email', 'avater', 'is_staff', 'is_active', 'is_superuser']
    list_filter = ['is_staff', 'is_active']
    fieldsets = (
        (None, {
            'fields': ('email', 'avater', 'password', 'is_staff', 'is_active', 'is_superuser')
            }
        ),
        ('Permissions', {
            'fields': ('groups', 'user_permissions')
            }
        ),
    )
    add_fieldsets = (
        (None,{'fields': ('email','avater', 'approver', 'password1', 'password2', 'is_staff', 'is_active', 'is_superuser')}),
    )
    search_fields = ['email',]
    ordering = ['email',]
    readonly_fields = ['id']
class CustomOutstandingTokenAdmin(admin.ModelAdmin):
    list_deisplay = ('user', 'jti', 'created_at', 'expires_at')
class CustomBlackListTokenAdmin(admin.ModelAdmin):
    list_display = ('token', 'blacklisted_at')
admin.site.register(CustomUser, CustomUserAdmin)
admin.site.register(GeneratePublicToken)
admin.site.register(GenerateGroup)
admin.site.register(CustomOutStandingToken, CustomOutstandingTokenAdmin)
admin.site.register(CustomBlackListToken, CustomBlackListTokenAdmin)
admin.site.register(Goal)
