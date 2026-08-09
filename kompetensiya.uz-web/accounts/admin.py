from django.contrib import admin

from .models import ApiToken, Profile


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'region', 'specialty', 'score', 'one_id_verified']
    list_filter = ['region', 'one_id_verified']
    search_fields = ['user__username', 'user__first_name', 'user__last_name']


@admin.register(ApiToken)
class ApiTokenAdmin(admin.ModelAdmin):
    list_display = ['user', 'created_at', 'last_used_at']
    search_fields = ['user__username', 'key']
    readonly_fields = ['key', 'created_at', 'last_used_at']
