from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone

from news.models import CARD_COLORS


class Vacancy(models.Model):
    WORK_TYPES = [
        ('Ofisda', 'Ofisda'),
        ('Gibrid', 'Gibrid'),
        ('Masofaviy', 'Masofaviy'),
    ]
    FIELDS = [
        ('IT', 'IT'),
        ('Moliya', 'Moliya'),
        ('Marketing', 'Marketing'),
        ("Ta'lim", "Ta'lim"),
        ('Sanoat', 'Sanoat'),
        ('Telekommunikatsiya', 'Telekommunikatsiya'),
        ('Huquq', 'Huquq'),
        ('Boshqaruv', 'Boshqaruv'),
    ]
    CURRENCIES = [('UZS', "so'm"), ('USD', 'USD')]

    company = models.CharField('Kompaniya', max_length=120)
    position = models.CharField('Lavozim', max_length=120)
    description = models.TextField('Tavsif', blank=True)
    location = models.CharField('Manzil', max_length=120)
    salary_min = models.PositiveIntegerField('Maosh (min)', default=0)
    salary_max = models.PositiveIntegerField('Maosh (max)', default=0)
    currency = models.CharField('Valyuta', max_length=3, choices=CURRENCIES, default='UZS')
    work_type = models.CharField('Ish turi', max_length=12, choices=WORK_TYPES, default='Ofisda')
    field = models.CharField('Soha', max_length=30, choices=FIELDS, default='IT')
    card_color = models.CharField('Karta rangi', max_length=10, choices=CARD_COLORS, default='blue')
    is_urgent = models.BooleanField('Shoshilinch', default=False)
    logo_url = models.URLField('Logo (URL)', blank=True)
    is_active = models.BooleanField('Faol', default=True)
    created_at = models.DateTimeField('Yaratilgan', auto_now_add=True)

    class Meta:
        verbose_name = 'Vakansiya'
        verbose_name_plural = 'Vakansiyalar'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.position} — {self.company}'

    @property
    def is_new(self):
        return (timezone.now() - self.created_at).days <= 2

    @property
    def days_ago(self):
        return max((timezone.now() - self.created_at).days, 0)

    @property
    def salary_display(self):
        if self.currency == 'USD':
            return f'${self.salary_min:,} - ${self.salary_max:,}'
        return f'{self.salary_min:,} - {self.salary_max:,} so\'m'.replace(',', ' ')


class Application(models.Model):
    STATUS_CHOICES = [
        ('pending', "Ko'rib chiqilmoqda"),
        ('reviewing', 'Suhbat bosqichida'),
        ('accepted', 'Qabul qilindi'),
        ('rejected', 'Rad etildi'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='applications', verbose_name='Foydalanuvchi')
    vacancy = models.ForeignKey(Vacancy, on_delete=models.CASCADE, related_name='applications', verbose_name='Vakansiya')
    cover_letter = models.TextField('Xat', blank=True)
    status = models.CharField('Holat', max_length=12, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField('Yuborilgan', auto_now_add=True)

    class Meta:
        verbose_name = 'Ariza'
        verbose_name_plural = 'Arizalar'
        unique_together = ['user', 'vacancy']
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user} → {self.vacancy}'
