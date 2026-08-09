from django.contrib import admin

from .models import Comment, Event, EventAttendance, Post


class CommentInline(admin.TabularInline):
    model = Comment
    extra = 0


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['author', 'content', 'created_at']
    search_fields = ['content', 'author__username']
    inlines = [CommentInline]


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['title', 'location', 'date', 'is_active']
    list_filter = ['is_active']
    search_fields = ['title', 'location']


@admin.register(EventAttendance)
class EventAttendanceAdmin(admin.ModelAdmin):
    list_display = ['user', 'event', 'checked_in_at', 'via_qr']
    list_filter = ['via_qr', 'event']
