import json
import logging
import secrets
import urllib.error
import urllib.parse
import urllib.request

from django.conf import settings
from django.contrib import messages
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.shortcuts import redirect, render
from django.urls import reverse
from django.utils import timezone

from assessments.models import TestResult
from community.models import EventAttendance
from courses.models import Enrollment
from performance.models import AttendanceRecord
from vacancies.models import Application

from .forms import ProfileForm


def login_view(request):
    """Kirish sahifasi — faqat ONE ID orqali."""
    if request.user.is_authenticated:
        return redirect('news:home')
    return render(request, 'accounts/login.html', {
        'one_id_configured': bool(settings.ONE_ID_CLIENT_ID),
    })


def logout_view(request):
    logout(request)
    return redirect('news:landing')


# ── ONE ID (id.egov.uz) OAuth2 ──────────────────────────────────────────────

logger = logging.getLogger(__name__)


class OneIdError(Exception):
    """ONE ID serveri qaytargan xatolik."""


def _one_id_request(payload):
    """ONE ID serveriga so'rov yuborib JSON javob qaytaradi."""
    data = urllib.parse.urlencode(payload).encode()
    req = urllib.request.Request(settings.ONE_ID_URL, data=data, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors='replace')[:500]
        # Maxfiy kalit hech qachon jurnalga tushmasligi uchun faqat javob yoziladi
        logger.warning('ONE ID xatoligi (HTTP %s): %s', exc.code, body)
        try:
            detail = json.loads(body)
            message = detail.get('error') or detail.get('message') or body
        except ValueError:
            message = body
        raise OneIdError(f'ONE ID: {message}') from exc


def one_id_redirect_uri(request):
    """ONE ID ga yuboriladigan callback manzili.

    Sozlamalarda `ONE_ID_REDIRECT_URL` berilgan bo'lsa aynan o'sha
    ishlatiladi — ONE ID kabinetida ro'yxatdan o'tkazilgan manzil bilan
    belgi-ma-belgi mos kelishi shart. Aks holda joriy so'rovdan hisoblanadi.
    """
    if settings.ONE_ID_REDIRECT_URL:
        return settings.ONE_ID_REDIRECT_URL
    return request.build_absolute_uri(reverse('accounts:one_id_callback'))


def one_id_user_from_code(code, redirect_uri):
    """ONE ID `code`ni foydalanuvchiga almashtiradi.

    `(user, None)` yoki xatolik holatida `(None, xabar)` qaytaradi.
    Veb (callback) va mobil ilova (API) uchun umumiy.
    """
    try:
        token = _one_id_request({
            'grant_type': 'one_authorization_code',
            'client_id': settings.ONE_ID_CLIENT_ID,
            'client_secret': settings.ONE_ID_CLIENT_SECRET,
            'redirect_uri': redirect_uri,
            'code': code,
        })
        access_token = token['access_token']
        info = _one_id_request({
            'grant_type': 'one_access_token_identify',
            'client_id': settings.ONE_ID_CLIENT_ID,
            'client_secret': settings.ONE_ID_CLIENT_SECRET,
            'access_token': access_token,
            'scope': settings.ONE_ID_SCOPE or settings.ONE_ID_CLIENT_ID,
        })
    except OneIdError as exc:
        return None, str(exc)
    except KeyError:
        return None, 'ONE ID javobida access_token topilmadi.'
    except Exception:
        logger.exception('ONE ID bilan bog\'lanishda kutilmagan xatolik')
        return None, "ONE ID serveri bilan bog'lanib bo'lmadi. Keyinroq urinib ko'ring."

    pin = str(info.get('pin') or info.get('user_id') or '').strip()
    if not pin:
        return None, "ONE ID foydalanuvchi ma'lumotlari olinmadi."

    user, created = User.objects.get_or_create(
        username=f'oneid_{pin}',
        defaults={
            'first_name': (info.get('first_name') or '').title(),
            'last_name': (info.get('sur_name') or info.get('last_name') or '').title(),
            'email': info.get('email') or '',
        },
    )
    if created:
        user.set_unusable_password()
        user.save()
    profile = user.profile
    profile.one_id_verified = True
    if info.get('mob_phone_no'):
        profile.phone = info['mob_phone_no']
    profile.save()
    return user, None


def one_id_start(request):
    """ONE ID tugmasi bosilganda: avtorizatsiya sahifasiga yo'naltirish."""
    if request.user.is_authenticated:
        return redirect('news:home')

    if not settings.ONE_ID_CLIENT_ID:
        messages.error(
            request,
            'ONE ID hali sozlanmagan. Tizimga kirish uchun serverda '
            'ONE_ID_CLIENT_ID va ONE_ID_CLIENT_SECRET qiymatlarini kiriting.',
        )
        return redirect('accounts:login')

    state = settings.ONE_ID_STATE or secrets.token_urlsafe(16)
    request.session['one_id_state'] = state
    params = {
        'response_type': 'one_code',
        'client_id': settings.ONE_ID_CLIENT_ID,
        'redirect_uri': one_id_redirect_uri(request),
        'scope': settings.ONE_ID_SCOPE or settings.ONE_ID_CLIENT_ID,
        'state': state,
    }
    return redirect(f'{settings.ONE_ID_URL}?{urllib.parse.urlencode(params)}')


def one_id_callback(request):
    """ONE ID qaytargan code'ni token va foydalanuvchi ma'lumotlariga almashtirish."""
    code = request.GET.get('code')
    state = request.GET.get('state')
    saved_state = request.session.pop('one_id_state', None) or settings.ONE_ID_STATE
    if not code or not saved_state or state != saved_state:
        messages.error(request, "ONE ID orqali kirishda xatolik yuz berdi. Qayta urinib ko'ring.")
        return redirect('accounts:login')

    user, error = one_id_user_from_code(code, one_id_redirect_uri(request))
    if user is None:
        messages.error(request, error)
        return redirect('accounts:login')

    login(request, user)
    messages.success(request, 'ONE ID orqali muvaffaqiyatli kirdingiz!')
    return redirect('news:home')


# ── Profil ──────────────────────────────────────────────────────────────────

@login_required
def profile_view(request):
    user = request.user
    enrollments = Enrollment.objects.filter(user=user).select_related('course')
    applications = Application.objects.filter(user=user).select_related('vacancy')
    results = TestResult.objects.filter(user=user).select_related('assessment')
    today_gps = AttendanceRecord.objects.filter(
        user=user, method='gps', date=timezone.localdate()).first()
    qr_count = EventAttendance.objects.filter(user=user).count()
    context = {
        'profile': user.profile,
        'enrollments': enrollments,
        'applications': applications,
        'results': results,
        'certificates': enrollments.filter(certificate=True).count(),
        'today_gps': today_gps,
        'qr_count': qr_count,
    }
    return render(request, 'accounts/profile.html', context)


@login_required
def profile_edit_view(request):
    profile = request.user.profile
    form = ProfileForm(
        request.POST or None,
        instance=profile,
        initial={
            'first_name': request.user.first_name,
            'last_name': request.user.last_name,
        },
    )
    if request.method == 'POST' and form.is_valid():
        form.save()
        messages.success(request, "Ma'lumotlar saqlandi.")
        return redirect('accounts:profile')
    return render(request, 'accounts/profile_edit.html', {'form': form})
