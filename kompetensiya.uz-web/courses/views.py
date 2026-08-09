from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from .models import Course, Enrollment


def course_list(request):
    category = request.GET.get('turkum', 'Barchasi')
    level = request.GET.get('daraja', 'Barchasi')

    qs = Course.objects.filter(is_active=True)
    if category != 'Barchasi':
        qs = qs.filter(category=category)
    if level != 'Barchasi':
        qs = qs.filter(level=level)

    enrollments = {}
    if request.user.is_authenticated:
        enrollments = {
            e.course_id: e
            for e in Enrollment.objects.filter(user=request.user)
        }

    return render(request, 'courses/list.html', {
        'courses': qs,
        'categories': ['Barchasi'] + [c[0] for c in Course.CATEGORIES],
        'levels': ['Barchasi', "Boshlang'ich", "O'rta", 'Yuqori'],
        'selected_category': category,
        'selected_level': level,
        'enrollments': enrollments,
        'active_nav': 'courses',
    })


@login_required
@require_POST
def enroll(request, pk):
    course = get_object_or_404(Course, pk=pk, is_active=True)
    _, created = Enrollment.objects.get_or_create(user=request.user, course=course)
    if created:
        messages.success(request, f'"{course.title}" kursiga yozildingiz!')
    else:
        messages.info(request, 'Siz bu kursga allaqachon yozilgansiz.')
    return redirect(request.META.get('HTTP_REFERER') or 'courses:list')


@login_required
def my_courses(request):
    enrollments = Enrollment.objects.filter(user=request.user).select_related('course')
    return render(request, 'courses/my_courses.html', {
        'enrollments': enrollments,
        'active_nav': 'profile',
    })
