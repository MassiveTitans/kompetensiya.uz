from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import Count, Sum
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from accounts.models import Profile

from .models import Comment, Event, EventAttendance, Post


def community(request):
    tab = request.GET.get('tab', 'posts')
    if tab not in ('posts', 'events', 'rating'):
        tab = 'posts'

    posts = (
        Post.objects.select_related('author__profile')
        .prefetch_related('comments__author')
        .annotate(like_count=Count('likes', distinct=True),
                  comment_count=Count('comments', distinct=True))
    )
    events = Event.objects.filter(is_active=True)

    joined_ids = set()
    liked_ids = set()
    if request.user.is_authenticated:
        joined_ids = set(
            EventAttendance.objects.filter(user=request.user).values_list('event_id', flat=True)
        )
        liked_ids = set(request.user.liked_posts.values_list('id', flat=True))

    # Reyting
    rating_filter = request.GET.get('reyting', 'age')
    profiles = Profile.objects.select_related('user').filter(score__gt=0)
    by_region = (
        profiles.values('region')
        .annotate(total=Sum('score'), members=Count('id'))
        .order_by('-total')
    )

    return render(request, 'community/index.html', {
        'tab': tab,
        'posts': posts,
        'events': events,
        'joined_ids': joined_ids,
        'liked_ids': liked_ids,
        'rating_filter': rating_filter,
        'top_profiles': profiles[:10],
        'by_region': by_region[:10],
        'active_nav': 'community',
    })


@login_required
@require_POST
def create_post(request):
    content = request.POST.get('content', '').strip()
    if content:
        Post.objects.create(
            author=request.user,
            content=content,
            image_url=request.POST.get('image_url', '').strip(),
        )
        messages.success(request, 'Post joylandi!')
    return redirect('community:index')


@login_required
@require_POST
def toggle_like(request, pk):
    post = get_object_or_404(Post, pk=pk)
    if post.likes.filter(pk=request.user.pk).exists():
        post.likes.remove(request.user)
    else:
        post.likes.add(request.user)
    return redirect(request.META.get('HTTP_REFERER') or 'community:index')


@login_required
@require_POST
def add_comment(request, pk):
    post = get_object_or_404(Post, pk=pk)
    text = request.POST.get('text', '').strip()
    if text:
        Comment.objects.create(post=post, author=request.user, text=text)
    return redirect(request.META.get('HTTP_REFERER') or 'community:index')


@login_required
@require_POST
def join_event(request, pk):
    event = get_object_or_404(Event, pk=pk, is_active=True)
    _, created = EventAttendance.objects.get_or_create(user=request.user, event=event)
    if created:
        messages.success(request, f'"{event.title}" tadbiriga yozildingiz!')
    else:
        messages.info(request, 'Siz bu tadbirga allaqachon yozilgansiz.')
    return redirect(request.META.get('HTTP_REFERER') or 'community:index')
