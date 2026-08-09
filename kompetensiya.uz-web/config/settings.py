"""
Django settings for kompetensiya.uz — Istiqbolli Kadrlar platformasi.
"""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent


def _load_env_file(path):
    """`.env` faylidagi KALIT=qiymat juftliklarini muhitga yuklaydi.

    Tashqi kutubxona talab qilmaydi. Muhitda allaqachon berilgan qiymat
    ustunlik qiladi (serverdagi haqiqiy sozlamalar bekor qilinmasin).
    """
    if not path.exists():
        return
    for raw in path.read_text(encoding='utf-8').splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, _, value = line.partition('=')
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


_load_env_file(BASE_DIR / '.env')

SECRET_KEY = os.environ.get(
    'DJANGO_SECRET_KEY',
    'django-insecure-kompetensiya-uz-dev-key-o0zg2m4x9v'
)

DEBUG = os.environ.get('DJANGO_DEBUG', '1') == '1'

ALLOWED_HOSTS = [
    'kompetensiya.uz',
    'www.kompetensiya.uz',
    'test.kompetensiya.uz',
    'localhost',
    '127.0.0.1',
]

CSRF_TRUSTED_ORIGINS = [
    'https://kompetensiya.uz',
    'https://www.kompetensiya.uz',
    'https://test.kompetensiya.uz',
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    # Loyiha ilovalari
    'accounts',
    'news',
    'vacancies',
    'courses',
    'assessments',
    'community',
    'performance',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'uz'
TIME_ZONE = 'Asia/Tashkent'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'static']
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

LOGIN_URL = 'accounts:login'
LOGIN_REDIRECT_URL = 'news:home'
LOGOUT_REDIRECT_URL = 'news:landing'

# ── ONE ID (sso.egov.uz) OAuth2 ─────────────────────────────────────────────
# Qiymatlar `.env` faylidan yoki muhit o'zgaruvchilaridan olinadi.
# CLIENT_ID — ONE ID kabinetida berilgan foydalanuvchi nomi (username).
# Kalitlar berilmagan bo'lsa, tizimga kirish o'chiq bo'ladi.
ONE_ID_URL = os.environ.get(
    'ONE_ID_URL', 'https://sso.egov.uz/sso/oauth/Authorization.do')
ONE_ID_CLIENT_ID = os.environ.get('ONE_ID_CLIENT_ID', '')
ONE_ID_CLIENT_SECRET = os.environ.get('ONE_ID_CLIENT_SECRET', '')
ONE_ID_SCOPE = os.environ.get('ONE_ID_SCOPE', '')

# ONE ID kabinetida ro'yxatdan o'tkazilgan callback manzili.
# Bo'sh bo'lsa, joriy so'rovdan avtomatik hisoblanadi.
ONE_ID_REDIRECT_URL = os.environ.get('ONE_ID_REDIRECT_URL', '')

# Belgilangan `state` qiymati. Bo'sh bo'lsa har safar tasodifiy yaratiladi
# (xavfsizroq — CSRF himoyasi).
ONE_ID_STATE = os.environ.get('ONE_ID_STATE', '')

# HTTPS majburiyati. Standart holatda DEBUG=0 bo'lsa yoqiladi.
# Sertifikat hali tayyor bo'lmasa `DJANGO_SECURE_SSL=0` qo'ying —
# shunda sayt oddiy HTTP orqali ham ochiladi (DEBUG=0 qolgani holda).
SECURE_SSL = os.environ.get('DJANGO_SECURE_SSL', '0' if DEBUG else '1') == '1'

# Proksi ortida turganda sxemani sarlavhadan aniqlash — har doim kerak.
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

if SECURE_SSL:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
