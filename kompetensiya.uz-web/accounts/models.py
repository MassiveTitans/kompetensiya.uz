import secrets

from django.contrib.auth.models import User
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver

REGIONS = [
    ('Toshkent shahri', 'Toshkent shahri'),
    ('Toshkent viloyati', 'Toshkent viloyati'),
    ('Andijon', 'Andijon'),
    ('Buxoro', 'Buxoro'),
    ("Farg'ona", "Farg'ona"),
    ('Jizzax', 'Jizzax'),
    ('Xorazm', 'Xorazm'),
    ('Namangan', 'Namangan'),
    ('Navoiy', 'Navoiy'),
    ('Qashqadaryo', 'Qashqadaryo'),
    ("Qoraqalpog'iston", "Qoraqalpog'iston"),
    ('Samarqand', 'Samarqand'),
    ('Sirdaryo', 'Sirdaryo'),
    ('Surxondaryo', 'Surxondaryo'),
]


class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    phone = models.CharField('Telefon', max_length=20, blank=True)
    region = models.CharField('Hudud', max_length=40, choices=REGIONS, default='Toshkent shahri')
    specialty = models.CharField('Mutaxassislik', max_length=80, blank=True)
    birth_date = models.DateField("Tug'ilgan sana", null=True, blank=True)
    bio = models.TextField('Qisqacha', blank=True)
    score = models.PositiveIntegerField('Reyting bali', default=0)
    one_id_verified = models.BooleanField('ONE ID tasdiqlangan', default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Profil'
        verbose_name_plural = 'Profillar'
        ordering = ['-score']

    def __str__(self):
        return self.user.get_full_name() or self.user.username

    @property
    def initials(self):
        full = self.user.get_full_name()
        if full:
            parts = full.split()
            return ''.join(p[0] for p in parts[:2]).upper()
        return self.user.username[:2].upper()

    @property
    def age_group(self):
        if not self.birth_date:
            return '—'
        from datetime import date
        age = (date.today() - self.birth_date).days // 365
        if age <= 25:
            return '18-25'
        if age <= 35:
            return '26-35'
        return '36+'


class ApiToken(models.Model):
    """Mobil ilova uchun autentifikatsiya kaliti (ONE ID orqali beriladi)."""

    key = models.CharField('Kalit', max_length=64, unique=True, db_index=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='api_tokens',
                             verbose_name='Foydalanuvchi')
    created_at = models.DateTimeField('Yaratilgan', auto_now_add=True)
    last_used_at = models.DateTimeField("Oxirgi ishlatilgan", null=True, blank=True)

    class Meta:
        verbose_name = 'API kaliti'
        verbose_name_plural = 'API kalitlari'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user} — {self.key[:8]}…'

    @classmethod
    def issue(cls, user):
        return cls.objects.create(key=secrets.token_urlsafe(32), user=user)


@receiver(post_save, sender=User)
def create_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)
