from django.contrib import admin

from .models import Assessment, Choice, Question, TestResult


class ChoiceInline(admin.TabularInline):
    model = Choice
    extra = 2


class QuestionInline(admin.TabularInline):
    model = Question
    extra = 1
    show_change_link = True


@admin.register(Assessment)
class AssessmentAdmin(admin.ModelAdmin):
    list_display = ['title', 'kind', 'level', 'duration_minutes', 'question_count', 'is_active']
    list_filter = ['kind', 'level', 'is_active']
    search_fields = ['title']
    inlines = [QuestionInline]


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ['text', 'assessment', 'order']
    list_filter = ['assessment']
    inlines = [ChoiceInline]


@admin.register(TestResult)
class TestResultAdmin(admin.ModelAdmin):
    list_display = ['user', 'assessment', 'score', 'completed_at']
    list_filter = ['assessment']
    search_fields = ['user__username']
