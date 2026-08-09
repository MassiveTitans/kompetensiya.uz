# kompetensiya.uz (Django)

Platformaning veb-versiyasi. Django + Django template'lar
asosida qurilgan, dizayn mobil ilova (Flutter) bilan bir xil: Plus Jakarta Sans shrifti,
ko'k (#1565C0) asosiy rang, yumaloq kartalar, mobil qurilmada pastki navigatsiya.

## Bo'limlar (barchasi backendga bog'langan)

| Bo'lim | URL | Imkoniyatlar |
|---|---|---|
| Landing | `/` | Taqdimot sahifasi (`templates/news/landing.html`); "Kirish" tugmasi loginga yoki dashboardga yo'naltiradi |
| Asosiy | `/asosiy/` | Yangiliklar, bannerlar, turkum filtri, tezkor havolalar |
| Baholash | `/baholash/` | Ko'nikma/psixologik testlar, savollar, natija va reyting bali |
| Vakansiyalar | `/vakansiyalar/` | Qidiruv, soha filtri, ariza topshirish, ariza holati |
| Kurslar | `/kurslar/` | Turkum/daraja filtri, kursga yozilish, jarayon, sertifikat |
| Hamjamiyat | `/hamjamiyat/` | Postlar (layk, izoh), tadbirlar (qatnashish), reyting (podium, hudud) |
| Profil | `/hisob/profil/` | Statistika, davomat holati, test natijalari, ma'lumotlarni tahrirlash |
| Davomat | `/faoliyat/davomat/` | GPS kelish/ketish (brauzer geolokatsiyasi), QR kod davomat, tarix |
| KPI | `/faoliyat/kpi/` | 3 turkum ko'rsatkichlari, umumiy samaradorlik |
| Admin | `/admin/` | Barcha ma'lumotlarni boshqarish |

## Ishga tushirish (lokal)

```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Baza bo'sh holda ishga tushadi — **demo ma'lumotlar yo'q**. Yangiliklar, bannerlar,
vakansiyalar, kurslar, testlar, tadbirlar, KPI ko'rsatkichlari va ish hududi
`/admin/` orqali kiritiladi; veb-sayt ham, mobil ilova ham faqat shu bazadagi
ma'lumotni ko'rsatadi.

**Kirish — faqat ONE ID orqali.** `ONE_ID_CLIENT_ID` sozlanmagan bo'lsa kirish
ishlamaydi (demo rejim olib tashlangan) — login sahifasi kalitlarni sozlash
kerakligini ko'rsatadi. Lokal sinov uchun `/admin/` orqali superuser bilan kiring:
admin sessiyasi saytda ham amal qiladi.

### ONE ID sozlamalari

Qiymatlar loyiha ildizidagi **`.env`** faylidan o'qiladi (`.gitignore` da, git'ga
tushmaydi). Namuna: `.env.example`. Muhit o'zgaruvchisi sifatida berilgan qiymat
`.env` dagidan ustun turadi — serverda shu usul afzal.

| O'zgaruvchi | Ma'nosi |
|---|---|
| `ONE_ID_URL` | ONE ID endpointi (standart: `https://sso.egov.uz/sso/oauth/Authorization.do`) |
| `ONE_ID_CLIENT_ID` | ONE ID kabinetidagi **username** |
| `ONE_ID_CLIENT_SECRET` | maxfiy kalit |
| `ONE_ID_SCOPE` | ruxsat doirasi (masalan `myportal`) |
| `ONE_ID_REDIRECT_URL` | kabinetda ro'yxatdan o'tkazilgan callback manzili — **belgi-ma-belgi mos bo'lishi shart**. Bo'sh bo'lsa joriy so'rovdan hisoblanadi |
| `ONE_ID_STATE` | belgilangan `state`. Bo'sh bo'lsa har safar tasodifiy yaratiladi (xavfsizroq) |

Callback uchun uchta manzil ham ishlaydi:
`/one-id/callback`, `/one-id/callback/`, `/hisob/one-id/callback/` —
kabinetda ro'yxatdan o'tkazilgani `ONE_ID_REDIRECT_URL` ga yoziladi.

Mobil ilova ham shu sozlamadan foydalanadi: `/api/auth/one-id/` avtorizatsiya
manzilini va `redirectUri` ni qaytaradi, ilova uni WebView'da ochib, qaytgan
`code` ni `/api/auth/one-id/exchange/` ga yuboradi.

## Mobil ilova uchun API (`/api/`)

Flutter ilovasi (`kompetensiya.uz-app`) barcha ma'lumotni shu endpointlardan
oladi — ilovada qat'iy yozilgan ro'yxatlar qolmagan. Foydalanuvchiga tegishli
endpointlar `Authorization: Token <kalit>` sarlavhasini talab qiladi (kalit ONE ID
orqali `/api/auth/one-id/exchange/` dan olinadi).

| Endpoint | Metod | Auth | Tavsif |
|---|---|---|---|
| `/api/auth/one-id/` | GET | — | ONE ID avtorizatsiya manzili va sozlanganlik holati |
| `/api/auth/one-id/exchange/` | POST | — | ONE ID `code` → API kaliti |
| `/api/auth/logout/` | POST | ✓ | Kalitlarni bekor qilish |
| `/api/me/` | GET | ✓ | Profil, statistika, bugungi davomat |
| `/api/news/`, `/api/banners/` | GET | — | Yangiliklar, bannerlar |
| `/api/vacancies/`, `/api/vacancies/fields/` | GET | — | Vakansiyalar va soha filtrlari |
| `/api/vacancies/<id>/apply/` | POST | ✓ | Ariza topshirish |
| `/api/courses/`, `/api/courses/filters/` | GET | — | Kurslar, turkum/daraja filtrlari |
| `/api/courses/<id>/enroll/` | POST | ✓ | Kursga yozilish |
| `/api/assessments/?kind=skill\|psych` | GET | — | Testlar (kirilgan bo'lsa natija bilan) |
| `/api/assessments/<id>/questions/` | GET | — | Savollar va variantlar |
| `/api/assessments/<id>/submit/` | POST | ✓ | Javoblarni yuborish, natija bazaga yoziladi |
| `/api/community/posts/`, `.../create/`, `.../<id>/like/`, `.../<id>/comment/` | GET/POST | POST uchun ✓ | Postlar |
| `/api/community/events/` | GET | — | Tadbirlar |
| `/api/rating/?by=age\|region\|overall` | GET | — | Reyting |
| `/api/kpi/` | GET | ✓ | KPI turkumlari va ko'rsatkichlari |
| `/api/attendance/` | GET | ✓ | Ish hududi, bugungi holat, GPS tarix |
| `/api/attendance/gps/` | POST | ✓ | Kelish/ketish (hudud radiusi tekshiriladi) |
| `/api/attendance/qr/` | POST | ✓ | Tadbir QR davomati |
| `/api/attendance/events/` | GET | ✓ | Qatnashgan tadbirlar |

## Ilovalar tuzilishi

- `accounts` — foydalanuvchi profili (hudud, mutaxassislik, reyting bali), ONE ID kirish, mobil ilova API kalitlari
- `api` — mobil ilova uchun JSON endpointlar (token autentifikatsiyasi, CORS)
- `news` — yangiliklar, bannerlar
- `vacancies` — vakansiyalar va arizalar
- `courses` — kurslar va yozilishlar
- `assessments` — testlar, savollar, javob variantlari, natijalar
- `community` — postlar, izohlar, layklar, tadbirlar, tadbir davomati
- `performance` — ish hududi (GPS zonasi), GPS/QR davomat yozuvlari, KPI turkumlari va ko'rsatkichlari

## kompetensiya.uz domeniga joylash (production)

1. Serverda muhit o'zgaruvchilarini o'rnating:
   ```bash
   export DJANGO_DEBUG=0
   export DJANGO_SECRET_KEY="<kuchli-maxfiy-kalit>"
   ```
2. Statik fayllarni yig'ing: `python manage.py collectstatic`
3. Gunicorn bilan ishga tushiring:
   ```bash
   gunicorn config.wsgi:application --bind 127.0.0.1:8001
   ```
4. Nginx namunasi:
   ```nginx
   server {
       server_name kompetensiya.uz www.kompetensiya.uz;
       location /static/ { alias /var/www/kompetensiya.uz/staticfiles/; }
       location /media/  { alias /var/www/kompetensiya.uz/media/; }
       location / {
           proxy_pass http://127.0.0.1:8001;
           proxy_set_header Host $host;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```
5. SSL: `certbot --nginx -d kompetensiya.uz -d www.kompetensiya.uz`

`ALLOWED_HOSTS` va `CSRF_TRUSTED_ORIGINS` sozlamalarida kompetensiya.uz allaqachon
ko'rsatilgan. `DEBUG=0` bo'lganda HTTPS majburiy yoqiladi (HSTS, secure cookie).

## Statik fayllar

```
static/
├── css/app.css                 sayt uslublari
├── vendor/bootstrap-icons/     ikonka shrifti
├── img/
│   ├── logo.png                brend logotipi (shaffof, oq+ko'k — quyuq fon uchun)
│   └── logo-mark.png           kvadrat belgi (ko'k konteyner ichida ishlatiladi)
├── favicon/
│   ├── favicon.ico             16/32/48/64/128/256 — kvadrat, ko'k fonda
│   ├── favicon-16x16.png, favicon-32x32.png
│   ├── apple-touch-icon.png    180×180
│   ├── icon-192.png, icon-512.png
│   └── site.webmanifest
└── landing/                    landing sahifa resurslari (css, js, images, fonts)
```

Landing sahifa Django shabloni: `templates/news/landing.html` (`{% load static %}`
bilan). Favicon havolalari `base.html`, `accounts/login.html` va `news/landing.html`
`<head>` qismida. Production'da `python manage.py collectstatic` hammasini
`staticfiles/` ga yig'adi.
