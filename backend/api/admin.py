from django.contrib import admin
from .models import CustomUser
from django.contrib.auth.admin import UserAdmin as baseUserAdmin
class CustomUserAdmin(baseUserAdmin):
    list_display = ['email', 'is_staff', 'is_active', 'is_superuser']
    list_filter = ['is_staff', 'is_active']
    fieldsets = (
        (None, {
            'fields': ('email', 'password', 'avatar', 'is_staff', 'is_active', 'is_superuser')
            }
        ),
        ('Permissions', {
            'fields': ('groups', 'user_permissions')
            }
        ),
        ('Important Dates', {
            'fields': ('last_login', 'date_joined')
            }
        ),
        ('Advanced Oprions', {
            'fields': ('id', ),
            }
        )
    )
    add_fieldsets = (
        (None,{'fields': ('email', 'password1', 'password2', 'is_staff', 'is_active', 'is_superuser')}),
    )
    search_fields = ['email', 'id']
    ordering = ['email',]
admin.site.register(CustomUser, CustomUserAdmin)

