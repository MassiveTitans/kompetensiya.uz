from django.shortcuts import get_object_or_404, render
from django.urls import reverse

from .models import Banner, News


def landing(request):
    """Landing sahifa — 'Kirish' tugmasi login yoki dashboardga yo'naltiriladi."""
    return render(request, 'news/landing.html', {
        'login_url': reverse('news:home') if request.user.is_authenticated
                     else reverse('accounts:login'),
    })


def home(request):
    category = request.GET.get('turkum', '')
    qs = News.objects.filter(is_published=True)
    if category:
        qs = qs.filter(category=category)
    context = {
        'news_list': qs[:20],
        'banners': Banner.objects.filter(is_active=True),
        'categories': [c[0] for c in News.CATEGORY_CHOICES],
        'active_category': category,
        'active_nav': 'home',
    }
    return render(request, 'news/home.html', context)


def news_detail(request, pk):
    item = get_object_or_404(News, pk=pk, is_published=True)
    others = News.objects.filter(is_published=True).exclude(pk=pk)[:4]
    return render(request, 'news/detail.html', {
        'item': item, 'others': others, 'active_nav': 'home',
    })
