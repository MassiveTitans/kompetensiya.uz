from django.contrib import admin

from .models import Banner, News


@admin.register(News)
class NewsAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'is_urgent', 'is_published', 'created_at']
    list_filter = ['category', 'is_urgent', 'is_published']
    search_fields = ['title', 'body']


@admin.register(Banner)
class BannerAdmin(admin.ModelAdmin):
    list_display = ['title', 'order', 'is_active']
    list_editable = ['order', 'is_active']
