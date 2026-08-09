from django.contrib import admin

from .models import Application, Vacancy


@admin.register(Vacancy)
class VacancyAdmin(admin.ModelAdmin):
    list_display = ['position', 'company', 'field', 'work_type', 'is_urgent', 'is_active', 'created_at']
    list_filter = ['field', 'work_type', 'is_urgent', 'is_active']
    search_fields = ['position', 'company']


@admin.register(Application)
class ApplicationAdmin(admin.ModelAdmin):
    list_display = ['user', 'vacancy', 'status', 'created_at']
    list_filter = ['status']
    search_fields = ['user__username', 'vacancy__position']
