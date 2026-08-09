"""Mobil ilova (Flutter) uchun JSON API.

Ilovadagi barcha ekranlar shu endpointlardan ma'lumot oladi — ilovada
qat'iy yozilgan (hardcode) ro'yxatlar yo'q. Kalit nomlari ilovadagi
widgetlar kutayotgan formatga mos (camelCase).
"""
import urllib.parse

from django.conf import settings
from django.db.models import Count, Prefetch, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone

from accounts.models import ApiToken, Profile
from assessments.models import Assessment, Question, TestResult
from community.models import Comment, Event, EventAttendance, Post
from courses.models import Course, Enrollment
from news.models import Banner, News
from performance.models import AttendanceRecord, KpiCategory, WorkZone
from performance.utils import distance_meters
from vacancies.models import Application, Vacancy

from .auth import api_view, json_response, request_json


def _time_ago(dt):
    delta = timezone.now() - dt
    minutes = int(delta.total_seconds() // 60)
    if minutes < 1:
        return 'hozirgina'
    if minutes < 60:
        return f'{minutes} daqiqa oldin'
    hours = minutes // 60
    if hours < 24:
        return f'{hours} soat oldin'
    days = hours // 24
    if days < 30:
        return f'{days} kun oldin'
    months = days // 30
    return f'{months} oy oldin'


MONTHS = ['YAN', 'FEV', 'MAR', 'APR', 'MAY', 'IYN',
          'IYL', 'AVG', 'SEN', 'OKT', 'NOY', 'DEK']


# ── Autentifikatsiya (ONE ID) ───────────────────────────────────────────────

@api_view(['GET'])
def one_id_config(request):
    """Ilova ONE ID sahifasini ochishi uchun kerakli manzil.

    `configured` false bo'lsa, serverda ONE ID kalitlari sozlanmagan va
    kirish imkonsiz — ilova buni foydalanuvchiga tushunarli qilib ko'rsatadi.
    """
    from accounts.views import one_id_redirect_uri

    if not settings.ONE_ID_CLIENT_ID:
        return {'configured': False, 'authorizeUrl': '', 'redirectUri': ''}

    redirect_uri = one_id_redirect_uri(request)
    params = {
        'response_type': 'one_code',
        'client_id': settings.ONE_ID_CLIENT_ID,
        'redirect_uri': redirect_uri,
        'scope': settings.ONE_ID_SCOPE or settings.ONE_ID_CLIENT_ID,
        'state': settings.ONE_ID_STATE or 'mobile',
    }
    return {
        'configured': True,
        'authorizeUrl': f'{settings.ONE_ID_URL}?{urllib.parse.urlencode(params)}',
        'redirectUri': redirect_uri,
    }


@api_view(['POST'])
def one_id_exchange(request):
    """ONE ID qaytargan `code`ni API kalitiga almashtiradi."""
    from accounts.views import one_id_redirect_uri, one_id_user_from_code

    data = request_json(request)
    code = (data.get('code') or '').strip()
    redirect_uri = data.get('redirectUri') or one_id_redirect_uri(request)
    if not code:
        return json_response({'detail': "ONE ID kodi yuborilmadi"}, status=400)

    user, error = one_id_user_from_code(code, redirect_uri)
    if user is None:
        return json_response({'detail': error}, status=400)

    token = ApiToken.issue(user)
    return {'token': token.key, 'user': _profile_payload(user)}


@api_view(['POST'], login_required=True)
def logout(request):
    ApiToken.objects.filter(user=request.api_user).delete()
    return {'ok': True}


# ── Profil ──────────────────────────────────────────────────────────────────

def _profile_payload(user):
    profile = user.profile
    enrollments = Enrollment.objects.filter(user=user)
    today_gps = AttendanceRecord.objects.filter(
        user=user, method='gps', date=timezone.localdate()).first()
    return {
        'id': user.id,
        'fullName': user.get_full_name() or user.username,
        'initials': profile.initials,
        'email': user.email,
        'phone': profile.phone,
        'region': profile.region,
        'specialty': profile.specialty,
        'bio': profile.bio,
        'score': profile.score,
        'ageGroup': profile.age_group,
        'oneIdVerified': profile.one_id_verified,
        'coursesCount': enrollments.count(),
        'activeCoursesCount': enrollments.filter(progress__lt=100).count(),
        'applicationsCount': Application.objects.filter(user=user).count(),
        'certificatesCount': enrollments.filter(certificate=True).count(),
        'eventAttendanceCount': EventAttendance.objects.filter(user=user).count(),
        'testResultsCount': TestResult.objects.filter(user=user).count(),
        'gpsToday': {
            'checkedIn': True,
            'checkIn': today_gps.check_in.strftime('%H:%M') if today_gps.check_in else '',
            'checkOut': today_gps.check_out.strftime('%H:%M') if today_gps.check_out else '',
            'status': today_gps.status,
            'statusLabel': today_gps.get_status_display(),
            'location': today_gps.location_name,
        } if today_gps else {'checkedIn': False},
    }


@api_view(['GET'], login_required=True)
def me(request):
    return _profile_payload(request.api_user)


# ── Kontent ─────────────────────────────────────────────────────────────────

@api_view(['GET'])
def news_list(request):
    return [
        {
            'id': str(n.id),
            'title': n.title,
            'body': n.body,
            'category': n.category,
            'timeAgo': _time_ago(n.created_at),
            'isUrgent': n.is_urgent,
            'cardColor': n.card_color,
            'imageUrl': n.image_url,
            'semanticLabel': n.title,
        }
        for n in News.objects.filter(is_published=True)[:50]
    ]


@api_view(['GET'])
def banner_list(request):
    return [
        {
            'id': b.id,
            'title': b.title,
            'subtitle': b.subtitle,
            'ctaLabel': 'Batafsil',
            'link': b.link,
            'imageUrl': b.image_url,
            'semanticLabel': b.title,
            'accentColor': b.color,
        }
        for b in Banner.objects.filter(is_active=True)
    ]


@api_view(['GET'])
def vacancy_list(request):
    user = request.api_user
    applied = set()
    if user:
        applied = set(Application.objects.filter(user=user)
                      .values_list('vacancy_id', flat=True))
    qs = Vacancy.objects.filter(is_active=True).annotate(apps_count=Count('applications'))
    return [
        {
            'id': str(v.id),
            'company': v.company,
            'position': v.position,
            'description': v.description,
            'location': v.location,
            'salaryMin': v.salary_min,
            'salaryMax': v.salary_max,
            'currency': v.currency,
            'workType': v.work_type,
            'field': v.field,
            'cardColor': v.card_color,
            'isUrgent': v.is_urgent,
            'isNew': v.is_new,
            'logoUrl': v.logo_url,
            'logoSemanticLabel': f'{v.company} logotipi',
            'postedDaysAgo': v.days_ago,
            'applicants': v.apps_count,
            'isApplied': v.id in applied,
        }
        for v in qs
    ]


@api_view(['GET'])
def vacancy_fields(request):
    """Vakansiya filtrlari — modeldagi soha ro'yxatidan olinadi."""
    return {
        'filters': ['Barchasi'] + [f[0] for f in Vacancy.FIELDS] + ['Masofaviy'],
    }


@api_view(['POST'], login_required=True)
def vacancy_apply(request, pk):
    vacancy = get_object_or_404(Vacancy, pk=pk, is_active=True)
    data = request_json(request)
    _, created = Application.objects.get_or_create(
        user=request.api_user, vacancy=vacancy,
        defaults={'cover_letter': data.get('coverLetter', '')},
    )
    return {
        'ok': True,
        'created': created,
        'message': ('Ariza yuborildi!' if created
                    else 'Siz bu vakansiyaga allaqachon ariza topshirgansiz.'),
    }


@api_view(['GET'])
def course_list(request):
    user = request.api_user
    enrollments = {}
    if user:
        enrollments = {e.course_id: e for e in Enrollment.objects.filter(user=user)}
    qs = Course.objects.filter(is_active=True).annotate(students=Count('enrollments'))
    return [
        {
            'id': str(c.id),
            'title': c.title,
            'description': c.description,
            'category': c.category,
            'duration': f'{c.duration_hours} soat',
            'level': c.level,
            'students': c.students,
            'isEnrolled': c.id in enrollments,
            'progress': (enrollments[c.id].progress / 100) if c.id in enrollments else 0.0,
            'cardColor': c.card_color,
            'imageUrl': c.image_url,
            'semanticLabel': c.title,
        }
        for c in qs
    ]


@api_view(['GET'])
def course_filters(request):
    """Kurs filtrlari — modeldagi turkum va daraja ro'yxatlaridan."""
    from courses.models import LEVELS
    return {
        'categories': ['Barchasi'] + [c[0] for c in Course.CATEGORIES],
        'levels': ['Barchasi'] + [lvl[0] for lvl in LEVELS],
    }


@api_view(['POST'], login_required=True)
def course_enroll(request, pk):
    course = get_object_or_404(Course, pk=pk, is_active=True)
    _, created = Enrollment.objects.get_or_create(user=request.api_user, course=course)
    return {
        'ok': True,
        'created': created,
        'message': (f'"{course.title}" kursiga yozildingiz!' if created
                    else 'Siz bu kursga allaqachon yozilgansiz.'),
    }


# ── Baholash (testlar) ──────────────────────────────────────────────────────

@api_view(['GET'])
def assessment_list(request):
    kind = request.GET.get('kind', 'skill')
    if kind not in ('skill', 'psych'):
        kind = 'skill'

    best = {}
    user = request.api_user
    if user:
        for r in TestResult.objects.filter(user=user):
            if r.assessment_id not in best or r.score > best[r.assessment_id].score:
                best[r.assessment_id] = r

    qs = (Assessment.objects.filter(is_active=True, kind=kind)
          .annotate(question_total=Count('questions')))
    items = []
    for a in qs:
        result = best.get(a.id)
        items.append({
            'id': a.id,
            'title': a.title,
            'icon': a.icon,
            'color': a.color,
            'kind': a.kind,
            'duration': f'{a.duration_minutes} daqiqa',
            'durationMinutes': a.duration_minutes,
            'questions': a.question_total,
            'level': a.level,
            'isCompleted': result is not None,
            'score': round(result.score) if result else None,
        })
    return items


@api_view(['GET'])
def assessment_questions(request, pk):
    assessment = get_object_or_404(
        Assessment.objects.prefetch_related(
            Prefetch('questions', queryset=Question.objects.prefetch_related('choices'))
        ),
        pk=pk, is_active=True,
    )
    items = []
    for q in assessment.questions.all():
        choices = list(q.choices.all())
        correct = -1
        if assessment.kind == 'skill':
            for i, c in enumerate(choices):
                if c.is_correct:
                    correct = i
                    break
        items.append({
            'id': q.id,
            'question': q.text,
            'options': [c.text for c in choices],
            'optionIds': [c.id for c in choices],
            'correctIndex': correct,
        })
    return items


@api_view(['POST'], login_required=True)
def assessment_submit(request, pk):
    """Ilovadan kelgan javoblarni saqlab, natijani bazaga yozadi.

    Kutilayotgan tana: {"answers": {"<savol id>": <variant id>, ...}}
    """
    assessment = get_object_or_404(
        Assessment.objects.prefetch_related(
            Prefetch('questions', queryset=Question.objects.prefetch_related('choices'))
        ),
        pk=pk, is_active=True,
    )
    questions = list(assessment.questions.all())
    if not questions:
        return json_response({'detail': 'Bu test uchun savollar kiritilmagan.'}, status=400)

    answers = request_json(request).get('answers') or {}
    correct = 0
    total_weight = 0
    max_weight = 0
    for q in questions:
        choices = list(q.choices.all())
        if assessment.kind == 'psych':
            max_weight += max((c.weight for c in choices), default=0)
        picked_id = answers.get(str(q.id))
        picked = next((c for c in choices if str(c.id) == str(picked_id)), None)
        if picked:
            if picked.is_correct:
                correct += 1
            total_weight += picked.weight

    if assessment.kind == 'psych' and max_weight:
        score = round(total_weight / max_weight * 100, 1)
    else:
        score = round(correct / len(questions) * 100, 1)

    TestResult.objects.create(
        user=request.api_user, assessment=assessment, score=score,
        correct_answers=correct, total_questions=len(questions),
    )
    profile = request.api_user.profile
    profile.score += int(score / 10)
    profile.save(update_fields=['score'])

    return {
        'score': score,
        'correctAnswers': correct,
        'totalQuestions': len(questions),
    }


# ── Hamjamiyat ──────────────────────────────────────────────────────────────

@api_view(['GET'])
def post_list(request):
    user = request.api_user
    liked = set()
    if user:
        liked = set(user.liked_posts.values_list('id', flat=True))
    qs = (
        Post.objects.select_related('author__profile')
        .annotate(like_count=Count('likes', distinct=True),
                  comment_count=Count('comments', distinct=True))
    )
    return [
        {
            'id': str(p.id),
            'type': 'post',
            'authorName': p.author.get_full_name() or p.author.username,
            'authorInitials': p.author.profile.initials,
            'timeAgo': _time_ago(p.created_at),
            'content': p.content,
            'imageUrl': p.image_url or None,
            'semanticLabel': '',
            'likes': p.like_count,
            'comments': p.comment_count,
            'isLiked': p.id in liked,
        }
        for p in qs[:50]
    ]


@api_view(['POST'], login_required=True)
def post_create(request):
    data = request_json(request)
    content = (data.get('content') or '').strip()
    if not content:
        return json_response({'detail': 'Post matni bo\'sh.'}, status=400)
    post = Post.objects.create(
        author=request.api_user,
        content=content,
        image_url=(data.get('imageUrl') or '').strip(),
    )
    return {'id': str(post.id), 'ok': True}


@api_view(['POST'], login_required=True)
def post_like(request, pk):
    post = get_object_or_404(Post, pk=pk)
    if post.likes.filter(pk=request.api_user.pk).exists():
        post.likes.remove(request.api_user)
        liked = False
    else:
        post.likes.add(request.api_user)
        liked = True
    return {'isLiked': liked, 'likes': post.likes.count()}


@api_view(['POST'], login_required=True)
def post_comment(request, pk):
    post = get_object_or_404(Post, pk=pk)
    text = (request_json(request).get('text') or '').strip()
    if not text:
        return json_response({'detail': 'Izoh bo\'sh.'}, status=400)
    Comment.objects.create(post=post, author=request.api_user, text=text)
    return {'ok': True, 'comments': post.comments.count()}


@api_view(['GET'])
def event_list(request):
    user = request.api_user
    joined = set()
    if user:
        joined = set(EventAttendance.objects.filter(user=user)
                     .values_list('event_id', flat=True))
    return [
        {
            'id': e.id,
            'month': MONTHS[e.date.month - 1],
            'day': str(e.date.day),
            'date': e.date.isoformat(),
            'title': e.title,
            'description': e.description,
            'location': e.location,
            'color': e.color,
            'isJoined': e.id in joined,
        }
        for e in Event.objects.filter(is_active=True, date__gte=timezone.localdate())
    ]


@api_view(['GET'])
def rating(request):
    by = request.GET.get('by', 'age')
    badges = {1: '\U0001F947', 2: '\U0001F948', 3: '\U0001F949'}
    me_id = request.api_user.id if request.api_user else None

    if by == 'region':
        rows = (
            Profile.objects.filter(score__gt=0)
            .values('region')
            .annotate(total=Sum('score'), members=Count('id'))
            .order_by('-total')
        )
        return [
            {
                'rank': i + 1,
                'name': r['region'],
                'region': 'Hudud',
                'members': f"{r['members']:,}".replace(',', ' '),
                'score': r['total'],
                'badge': badges.get(i + 1, ''),
            }
            for i, r in enumerate(rows[:20])
        ]

    profiles = Profile.objects.select_related('user').filter(score__gt=0)[:20]
    if by == 'overall':
        return [
            {
                'rank': i + 1,
                'name': p.user.get_full_name() or p.user.username,
                'region': p.region,
                'specialty': p.specialty or '—',
                'score': p.score,
                'badge': badges.get(i + 1, ''),
                'isMe': p.user_id == me_id,
            }
            for i, p in enumerate(profiles)
        ]
    return [
        {
            'rank': i + 1,
            'name': p.user.get_full_name() or p.user.username,
            'region': p.region,
            'age': p.age_group,
            'score': p.score,
            'badge': badges.get(i + 1, ''),
            'isMe': p.user_id == me_id,
        }
        for i, p in enumerate(profiles)
    ]


# ── Faoliyat: KPI va davomat ────────────────────────────────────────────────

@api_view(['GET'], login_required=True)
def kpi(request):
    user = request.api_user
    data = []
    for cat in KpiCategory.objects.prefetch_related('items'):
        items = [
            {
                'label': i.label,
                'value': i.value,
                'target': i.target,
                'unit': i.unit,
                'trend': i.trend,
                'isPositive': i.trend >= 0,
                'percent': i.percent,
            }
            for i in cat.items.all() if i.user_id == user.id
        ]
        if items:
            data.append({
                'title': cat.title,
                'icon': cat.icon,
                'color': cat.color,
                'kpis': items,
            })
    return data


def _attendance_payload(record, zone=None):
    distance = None
    if zone and record.latitude is not None and record.longitude is not None:
        distance = distance_meters(
            record.latitude, record.longitude, zone.latitude, zone.longitude)
    return {
        'id': record.id,
        'distanceMeters': distance,
        'date': record.date.isoformat(),
        'dateLabel': ('Bugun' if record.date == timezone.localdate()
                      else record.date.strftime('%d.%m.%Y')),
        'checkIn': record.check_in.strftime('%H:%M') if record.check_in else '',
        'checkOut': record.check_out.strftime('%H:%M') if record.check_out else '',
        'status': record.status,
        'statusLabel': record.get_status_display(),
        'location': record.location_name,
        'latitude': record.latitude,
        'longitude': record.longitude,
    }


@api_view(['GET'], login_required=True)
def attendance(request):
    """Ish hududi, GPS davomat tarixi va bugungi holat."""
    user = request.api_user
    today = timezone.localdate()
    records = list(AttendanceRecord.objects.filter(user=user, method='gps')[:30])
    today_record = next((r for r in records if r.date == today), None)
    zone = WorkZone.objects.filter(is_active=True).first()
    return {
        'zone': {
            'name': zone.name,
            'latitude': zone.latitude,
            'longitude': zone.longitude,
            'radiusMeters': zone.radius_meters,
        } if zone else None,
        'today': _attendance_payload(today_record, zone) if today_record else None,
        'history': [_attendance_payload(r, zone) for r in records],
    }


@api_view(['POST'], login_required=True)
def attendance_gps(request):
    """Ish joyida kelish/ketish vaqtini belgilaydi."""
    data = request_json(request)
    now = timezone.localtime()
    zone = WorkZone.objects.filter(is_active=True).first()
    latitude = data.get('latitude')
    longitude = data.get('longitude')

    # Ish hududi belgilangan bo'lsa, joylashuv radius ichida ekani tekshiriladi.
    if zone is not None:
        if latitude is None or longitude is None:
            return json_response(
                {'detail': 'Joylashuv aniqlanmadi. GPS ni yoqing.'}, status=400)
        distance = distance_meters(
            float(latitude), float(longitude), zone.latitude, zone.longitude)
        if distance > zone.radius_meters:
            return json_response({
                'detail': f'Siz ish hududidan tashqaridasiz ({distance} metr). '
                          'Davomat belgilanmadi.',
                'distanceMeters': distance,
            }, status=400)

    record, created = AttendanceRecord.objects.get_or_create(
        user=request.api_user, date=now.date(), method='gps',
        defaults={
            'check_in': now.time(),
            'status': 'late' if now.hour >= 9 else 'present',
            'location_name': data.get('locationName')
                             or (zone.name if zone else 'Ish joyi'),
            'latitude': latitude,
            'longitude': longitude,
        },
    )
    if created:
        message = f'Davomat belgilandi: {record.check_in:%H:%M}'
    elif not record.check_out:
        record.check_out = now.time()
        record.save(update_fields=['check_out'])
        message = f'Ketish vaqti belgilandi: {record.check_out:%H:%M}'
    else:
        message = 'Bugungi davomat allaqachon yakunlangan.'
    return {
        'ok': True,
        'message': message,
        'record': _attendance_payload(record, zone),
    }


@api_view(['GET'], login_required=True)
def event_attendance_list(request):
    """Foydalanuvchi QR orqali qatnashgan tadbirlar."""
    qs = (EventAttendance.objects.filter(user=request.api_user)
          .select_related('event').order_by('-checked_in_at'))
    return [
        {
            'id': a.id,
            'eventId': a.event_id,
            'name': a.event.title,
            'location': a.event.location,
            'date': a.event.date.isoformat(),
            'dateLabel': a.event.date.strftime('%d.%m.%Y'),
            'checkedInAt': timezone.localtime(a.checked_in_at).strftime('%H:%M'),
            'color': a.event.color,
            'viaQr': a.via_qr,
        }
        for a in qs
    ]


@api_view(['POST'], login_required=True)
def attendance_qr(request):
    """QR kod orqali tadbir davomatini belgilaydi."""
    code = (request_json(request).get('code') or '').strip()
    event = Event.objects.filter(qr_code=code, is_active=True).first() if code else None
    if not event:
        return json_response(
            {'detail': 'QR kod topilmadi yoki muddati tugagan.'}, status=404)
    _, created = EventAttendance.objects.get_or_create(
        user=request.api_user, event=event, defaults={'via_qr': True}
    )
    return {
        'ok': True,
        'created': created,
        'eventName': event.title,
        'message': (f'"{event.title}" tadbirida davomat belgilandi!' if created
                    else f'"{event.title}" tadbiridagi davomatingiz allaqachon qayd etilgan.'),
    }
