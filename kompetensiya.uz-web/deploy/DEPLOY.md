# Serverga joylash — kompetensiya.uz

Server: `89.249.63.115:35653`, foydalanuvchi `aiysgdde`, Ubuntu 22.04, Python 3.10.12
Nginx **hostda** ishlaydi (systemd), 80/443 portlarni u ushlab turadi.
Eski tizim **Docker Swarm** da (`docker compose` emas!).

Manzillar taqsimoti:

| Domen | Vazifasi |
|---|---|
| `kompetensiya.uz`, `www.` | **butun sayt** (Django) |
| `test.kompetensiya.uz` | **faqat** ONE ID callback → kompetensiya.uz ga uzatadi |

---

## 0-qadam. Zaxira (o'tkazib yubormang)

Eski postgres to'xtaguncha bazani saqlab oling:

```bash
docker exec $(docker ps -qf name=argos-academy-backend_postgres) \
  pg_dumpall -U postgres > ~/argos-db-$(date +%F).sql
ls -lh ~/argos-db-*.sql
```

Nginx konfiglari va sertifikatlar:

```bash
sudo tar czf ~/nginx-letsencrypt-$(date +%F).tar.gz /etc/nginx /etc/letsencrypt
```

---

## 1-qadam. Ishlayotgan servislarni to'xtatish

> **Diqqat:** bu `admin.kompetensiya.uz` va `backoffice.kompetensiya.uz`
> saytlarini ham o'chiradi — ular ham shu konteynerlarga bog'langan.
> `docker service rm` ishlatmang: `scale=0` qaytariladigan amal,
> servis ta'rifi va volume'lar joyida qoladi.

```bash
docker service scale \
  argos-academy-backend_backend=0 \
  argos-academy-backend_celery_beat=0 \
  argos-academy-backend_celery_worker=0 \
  argos-academy-backend_websokcet=0 \
  ylh-front-backoffice=0 \
  ylh-landing-frontend=0 \
  ylh-landing-user-backoffice=0
```

Zaxira olingach, baza va keshni ham:

```bash
docker service scale \
  argos-academy-backend_postgres=0 \
  argos-academy-backend_redis=0
```

Tekshirish — hammasi `0/0` bo'lishi kerak:

```bash
docker service ls
```

**Qaytarish kerak bo'lsa:** `docker service scale argos-academy-backend_backend=1` va hokazo.

---

## 2-qadam. Papka va virtual muhit

```bash
sudo apt update && sudo apt install -y python3-venv python3-pip

sudo mkdir -p /var/www/kompetensiya.uz
sudo chown -R aiysgdde:www-data /var/www/kompetensiya.uz
sudo chmod 755 /var/www/kompetensiya.uz

cd /var/www/kompetensiya.uz
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
```

---

## 3-qadam. Kodni yuborish (Windows PowerShell da)

Lokal kompyuterda, **yangi PowerShell oynasida**:

```powershell
cd C:\Users\Javlon\Desktop\YHL\yhl
tar --exclude=.venv --exclude=__pycache__ --exclude=staticfiles --exclude=db.sqlite3 --exclude=*.pyc -czf kompetensiya.tar.gz kompetensiya.uz
scp -P 35653 kompetensiya.tar.gz aiysgdde@89.249.63.115:~/
```

Keyin **serverda**:

```bash
cd /var/www/kompetensiya.uz
tar xzf ~/kompetensiya.tar.gz --strip-components=1
ls -la          # manage.py, config/, accounts/, .env ko'rinishi kerak
chmod 600 .env  # maxfiy kalit faqat egasiga o'qilsin
```

> Arxivda `db.sqlite3` yo'q — baza serverda toza holda yaratiladi.
> `.env` esa **bor** (ONE ID kalitlari bilan), shuning uchun `chmod 600`.

Keyingi safar yangilash uchun shu uchta buyruqni takrorlaysiz, so'ng
`sudo systemctl restart kompetensiya`.

---

## 4-qadam. Django sozlash

`.env` ni serverga moslang:

```bash
cd /var/www/kompetensiya.uz
nano .env
```

Quyidagi ikki qatorni **qo'shing/tuzating** (ONE ID qatorlari o'z holicha qolsin):

```
DJANGO_DEBUG=0
DJANGO_SECRET_KEY=<pastdagi buyruq bergan qiymat>
```

Kuchli kalit generatsiya qilish:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

`ONE_ID_REDIRECT_URL` **o'zgarmaydi** — ONE ID kabinetida ro'yxatdan
o'tgan manzil aynan shu:

```
ONE_ID_REDIRECT_URL=https://test.kompetensiya.uz/one-id/callback
```

Bog'liqliklar, baza va statik fayllar:

```bash
.venv/bin/pip install -r requirements.txt
.venv/bin/python manage.py migrate
.venv/bin/python manage.py collectstatic --noinput
.venv/bin/python manage.py createsuperuser
```

Fayl huquqlari (nginx statik fayllarni o'qiy olishi uchun):

```bash
chmod 664 db.sqlite3
mkdir -p media && chmod 775 media
```

---

## 5-qadam. Gunicorn (systemd)

```bash
sudo cp deploy/kompetensiya.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now kompetensiya
sudo systemctl status kompetensiya --no-pager
```

Ishlayotganini tekshiring — `200` yoki `301` qaytishi kerak:

```bash
curl -I -H "Host: kompetensiya.uz" http://127.0.0.1:8001/
```

Xatolik bo'lsa jurnalni ko'ring:

```bash
sudo journalctl -u kompetensiya -n 50 --no-pager
```

---

## 6-qadam. Nginx

Eski konfiglarni saqlang:

```bash
sudo cp /etc/nginx/sites-available/kompitensiya.uz      /root/kompitensiya.uz.eski-$(date +%F)
sudo cp /etc/nginx/sites-available/test.kompetensiya.uz /root/test.kompetensiya.uz.eski-$(date +%F)
```

> Serverdagi fayl nomida yozuv xatosi bor: **kompItensiya.uz**.
> Shu nomni o'zgartirmang — `sites-enabled` dagi symlink shunga bog'langan.

Yangilarini qo'ying:

```bash
cd /var/www/kompetensiya.uz
sudo cp deploy/nginx-kompetensiya.uz.conf      /etc/nginx/sites-available/kompitensiya.uz
sudo cp deploy/nginx-test.kompetensiya.uz.conf /etc/nginx/sites-available/test.kompetensiya.uz

sudo nginx -t && sudo systemctl reload nginx
```

`nginx -t` **muvaffaqiyatli** bo'lmasa reload qilmang — eski konfigni qaytaring.

---

## 7-qadam. Tekshirish

```bash
curl -I https://kompetensiya.uz/
curl -I https://kompetensiya.uz/asosiy/
curl -I https://kompetensiya.uz/static/css/app.css
curl -I https://kompetensiya.uz/api/news/

# callback uzatilishi: 302 va Location kompetensiya.uz ga ishora qilsin
curl -I "https://test.kompetensiya.uz/one-id/callback?code=aaa&state=state"
```

Oxirgi buyruq javobida quyidagicha qator bo'lishi kerak:

```
location: https://kompetensiya.uz/one-id/callback?code=aaa&state=state
```

So'ng brauzerda `https://kompetensiya.uz` ni oching va ONE ID orqali kiring.

---

## Orqaga qaytarish (rollback)

```bash
sudo systemctl stop kompetensiya
sudo cp /root/kompitensiya.uz.eski-<sana>      /etc/nginx/sites-available/kompitensiya.uz
sudo cp /root/test.kompetensiya.uz.eski-<sana> /etc/nginx/sites-available/test.kompetensiya.uz
sudo nginx -t && sudo systemctl reload nginx

docker service scale \
  argos-academy-backend_postgres=1 argos-academy-backend_redis=1 \
  argos-academy-backend_backend=1 argos-academy-backend_websokcet=1 \
  argos-academy-backend_celery_beat=1 argos-academy-backend_celery_worker=1 \
  ylh-front-backoffice=1 ylh-landing-frontend=1 ylh-landing-user-backoffice=1
```

---

## Keyinchalik

- **Reboot.** Serverda `*** System restart required ***` turibdi. Migratsiya
  yakunlangach qayta yuklang: `sudo reboot`. Gunicorn (`enable` qilingan) va
  nginx o'zi ko'tariladi.
- **SQLite.** Trafik oshsa PostgreSQL ga o'tish kerak bo'ladi — eski postgres
  konteyneri allaqachon bor, faqat yangi baza yaratiladi.
- **Zaxira.** `db.sqlite3` va `media/` uchun kunlik cron zaxirasini sozlang.
