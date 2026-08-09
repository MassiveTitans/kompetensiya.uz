from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from .models import Application, Vacancy

FILTERS = ['Barchasi', 'IT', 'Moliya', 'Marketing', "Ta'lim", 'Sanoat', 'Masofaviy']


def vacancy_list(request):
    q = request.GET.get('q', '').strip()
    selected = request.GET.get('filtr', 'Barchasi')

    qs = Vacancy.objects.filter(is_active=True).annotate(applicants=Count('applications'))
    if q:
        qs = qs.filter(Q(position__icontains=q) | Q(company__icontains=q))
    if selected == 'Masofaviy':
        qs = qs.filter(work_type='Masofaviy')
    elif selected != 'Barchasi':
        qs = qs.filter(field=selected)

    applied_ids = set()
    if request.user.is_authenticated:
        applied_ids = set(
            Application.objects.filter(user=request.user).values_list('vacancy_id', flat=True)
        )

    return render(request, 'vacancies/list.html', {
        'vacancies': qs,
        'filters': FILTERS,
        'selected': selected,
        'q': q,
        'applied_ids': applied_ids,
        'active_nav': 'vacancies',
    })


@login_required
@require_POST
def apply(request, pk):
    vacancy = get_object_or_404(Vacancy, pk=pk, is_active=True)
    _, created = Application.objects.get_or_create(
        user=request.user,
        vacancy=vacancy,
        defaults={'cover_letter': request.POST.get('cover_letter', '')},
    )
    if created:
        messages.success(
            request,
            f'Ariza yuborildi! {vacancy.company} kompaniyasi siz bilan bog\'lanadi.'
        )
    else:
        messages.info(request, 'Siz bu vakansiyaga allaqachon ariza topshirgansiz.')
    return redirect(request.META.get('HTTP_REFERER') or 'vacancies:list')


@login_required
def my_applications(request):
    apps_qs = Application.objects.filter(user=request.user).select_related('vacancy')
    return render(request, 'vacancies/my_applications.html', {
        'applications': apps_qs,
        'active_nav': 'profile',
    })
