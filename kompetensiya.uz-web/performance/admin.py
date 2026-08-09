from django.contrib import admin

from .models import AttendanceRecord, KpiCategory, KpiItem, WorkZone


@admin.register(WorkZone)
class WorkZoneAdmin(admin.ModelAdmin):
    list_display = ['name', 'latitude', 'longitude', 'radius_meters', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name']


@admin.register(AttendanceRecord)
class AttendanceRecordAdmin(admin.ModelAdmin):
    list_display = ['user', 'date', 'check_in', 'check_out', 'method', 'status']
    list_filter = ['method', 'status', 'date']
    search_fields = ['user__username']


class KpiItemInline(admin.TabularInline):
    model = KpiItem
    extra = 0


@admin.register(KpiCategory)
class KpiCategoryAdmin(admin.ModelAdmin):
    list_display = ['title', 'order']
    inlines = [KpiItemInline]


@admin.register(KpiItem)
class KpiItemAdmin(admin.ModelAdmin):
    list_display = ['user', 'label', 'value', 'target', 'unit', 'trend', 'category']
    list_filter = ['category']
    search_fields = ['user__username', 'label']
