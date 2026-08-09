from django.contrib.auth.models import User
from django.db import models

from news.models import CARD_COLORS


class Post(models.Model):
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts', verbose_name='Muallif')
    content = models.TextField('Matn')
    image_url = models.URLField('Rasm (URL)', blank=True)
    likes = models.ManyToManyField(User, related_name='liked_posts', blank=True, verbose_name='Layklar')
    created_at = models.DateTimeField('Yaratilgan', auto_now_add=True)

    class Meta:
        verbose_name = 'Post'
        verbose_name_plural = 'Postlar'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.author}: {self.content[:50]}'


class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments', verbose_name='Post')
    author = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name='Muallif')
    text = models.TextField('Izoh')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Izoh'
        verbose_name_plural = 'Izohlar'
        ordering = ['created_at']

    def __str__(self):
        return f'{self.author}: {self.text[:40]}'


class Event(models.Model):
    title = models.CharField('Nomi', max_length=160)
    description = models.TextField('Tavsif', blank=True)
    location = models.CharField('Manzil', max_length=160)
    date = models.DateField('Sana')
    color = models.CharField('Rang', max_length=10, choices=CARD_COLORS, default='blue')
    image_url = models.URLField('Rasm (URL)', blank=True)
    qr_code = models.CharField('QR kod belgisi', max_length=64, blank=True,
                               help_text='Tadbirda davomat uchun QR kod qiymati')
    is_active = models.BooleanField('Faol', default=True)

    class Meta:
        verbose_name = 'Tadbir'
        verbose_name_plural = 'Tadbirlar'
        ordering = ['date']

    def __str__(self):
        return self.title

    @property
    def month_abbr(self):
        months = ['YAN', 'FEV', 'MAR', 'APR', 'MAY', 'IYN',
                  'IYL', 'AVG', 'SEN', 'OKT', 'NOY', 'DEK']
        return months[self.date.month - 1]


class EventAttendance(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='event_attendances', verbose_name='Foydalanuvchi')
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='attendances', verbose_name='Tadbir')
    checked_in_at = models.DateTimeField('Belgilangan vaqt', auto_now_add=True)
    via_qr = models.BooleanField('QR orqali', default=False)

    class Meta:
        verbose_name = 'Tadbir davomati'
        verbose_name_plural = 'Tadbir davomatlari'
        unique_together = ['user', 'event']

    def __str__(self):
        return f'{self.user} → {self.event}'
