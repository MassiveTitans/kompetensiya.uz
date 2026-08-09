"""Mobil ilova uchun autentifikatsiya va CORS yordamchilari.

Ilova har bir so'rovda `Authorization: Token <kalit>` sarlavhasini yuboradi.
Veb-brauzerdan kelgan so'rovlarda odatdagi Django sessiyasi ishlaydi.
"""
import functools
import json

from django.http import HttpResponse, JsonResponse
from django.utils import timezone

from accounts.models import ApiToken

CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
}


def json_response(data, status=200):
    """CORS ruxsati bilan JSON javob (ilova va veb-klientlar uchun)."""
    resp = JsonResponse(data, safe=False, status=status,
                        json_dumps_params={'ensure_ascii': False})
    for name, value in CORS_HEADERS.items():
        resp[name] = value
    return resp


def api_user(request):
    """So'rov egasini aniqlaydi: avval token, so'ng sessiya. Topilmasa None."""
    header = request.META.get('HTTP_AUTHORIZATION', '')
    if header.lower().startswith('token '):
        key = header[6:].strip()
        token = ApiToken.objects.select_related('user').filter(key=key).first()
        if token:
            ApiToken.objects.filter(pk=token.pk).update(last_used_at=timezone.now())
            return token.user
        return None
    if request.user.is_authenticated:
        return request.user
    return None


def request_json(request):
    """So'rov tanasini dict sifatida qaytaradi (JSON yoki form-data)."""
    if request.content_type and 'application/json' in request.content_type:
        try:
            data = json.loads(request.body.decode() or '{}')
        except (ValueError, UnicodeDecodeError):
            return {}
        return data if isinstance(data, dict) else {}
    return request.POST.dict()


def api_view(methods=('GET',), login_required=False):
    """Endpointlarni CORS, metod tekshiruvi va autentifikatsiya bilan o'raydi.

    O'ralgan funksiya `request` va (kerak bo'lsa) `request.api_user` bilan
    chaqiriladi; qaytargan qiymati JSON'ga o'giriladi.
    """
    allowed = tuple(m.upper() for m in methods)

    def decorator(func):
        @functools.wraps(func)
        def wrapper(request, *args, **kwargs):
            if request.method == 'OPTIONS':
                resp = HttpResponse(status=204)
                for name, value in CORS_HEADERS.items():
                    resp[name] = value
                return resp
            if request.method not in allowed:
                return json_response({'detail': 'Method not allowed'}, status=405)

            request.api_user = api_user(request)
            if login_required and request.api_user is None:
                return json_response({'detail': 'Autentifikatsiya talab etiladi'}, status=401)

            result = func(request, *args, **kwargs)
            if isinstance(result, HttpResponse):
                return result
            return json_response(result)

        wrapper.csrf_exempt = True
        return wrapper

    return decorator
