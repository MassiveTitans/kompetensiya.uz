from django.contrib import admin

from .models import Course, Enrollment


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'level', 'duration_hours', 'is_active']
    list_filter = ['category', 'level', 'is_active']
    search_fields = ['title']


@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ['user', 'course', 'progress', 'certificate', 'enrolled_at']
    list_filter = ['certificate']
    search_fields = ['user__username', 'course__title']
