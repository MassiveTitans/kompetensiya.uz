from django.contrib.auth.models import User
from django.db import models

from news.models import CARD_COLORS


class WorkZone(models.Model):
    """Davomat belgilanadigan ish hududi (GPS)."""

    name = models.CharField('Nomi', max_length=160)
    latitude = models.FloatField('Kenglik')
    longitude = models.FloatField('Uzunlik')
    radius_meters = models.PositiveIntegerField('Radius (metr)', default=200)
    is_active = models.BooleanField('Faol', default=True)

    class Meta:
        verbose_name = 'Ish hududi'
        verbose_name_plural = 'Ish hududlari'
        ordering = ['name']

    def __str__(self):
        return self.name


class AttendanceRecord(models.Model):
    METHODS = [('gps', 'GPS'), ('qr', 'QR kod')]
    STATUSES = [
        ('present', 'Ishda'),
        ('late', 'Kechikkan'),
        ('absent', 'Kelmagan'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='attendance_records', verbose_name='Foydalanuvchi')
    date = models.DateField('Sana')
    check_in = models.TimeField('Kelish vaqti', null=True, blank=True)
    check_out = models.TimeField('Ketish vaqti', null=True, blank=True)
    method = models.CharField('Usul', max_length=3, choices=METHODS, default='gps')
    status = models.CharField('Holat', max_length=8, choices=STATUSES, default='present')
    location_name = models.CharField('Joylashuv', max_length=160, blank=True)
    latitude = models.FloatField('Kenglik', null=True, blank=True)
    longitude = models.FloatField('Uzunlik', null=True, blank=True)

    class Meta:
        verbose_name = 'Davomat yozuvi'
        verbose_name_plural = 'Davomat yozuvlari'
        unique_together = ['user', 'date', 'method']
        ordering = ['-date']

    def __str__(self):
        return f'{self.user} — {self.date} ({self.get_status_display()})'


class KpiCategory(models.Model):
    title = models.CharField('Nomi', max_length=80)
    icon = models.CharField('Belgi', max_length=20, default='trending')
    color = models.CharField('Rang', max_length=10, choices=CARD_COLORS, default='blue')
    order = models.PositiveSmallIntegerField('Tartib', default=0)

    class Meta:
        verbose_name = 'KPI turkumi'
        verbose_name_plural = 'KPI turkumlari'
        ordering = ['order']

    def __str__(self):
        return self.title


class KpiItem(models.Model):
    category = models.ForeignKey(KpiCategory, on_delete=models.CASCADE, related_name='items', verbose_name='Turkum')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='kpi_items', verbose_name='Foydalanuvchi')
    label = models.CharField("Ko'rsatkich", max_length=100)
    value = models.FloatField('Qiymat', default=0)
    target = models.FloatField('Maqsad', default=100)
    unit = models.CharField("O'lchov birligi", max_length=10, default='%')
    trend = models.FloatField("O'zgarish", default=0)

    class Meta:
        verbose_name = "KPI ko'rsatkichi"
        verbose_name_plural = "KPI ko'rsatkichlari"

    def __str__(self):
        return f'{self.user} — {self.label}'

    @property
    def percent(self):
        if not self.target:
            return 0
        return min(round(self.value / self.target * 100), 100)
