from django.contrib.auth.models import User
from django.db import models

from news.models import CARD_COLORS

LEVELS = [
    ("Boshlang'ich", "Boshlang'ich"),
    ("O'rta", "O'rta"),
    ('Yuqori', 'Yuqori'),
]


class Course(models.Model):
    CATEGORIES = [
        ('IT', 'IT'),
        ('Moliya', 'Moliya'),
        ('Marketing', 'Marketing'),
        ('Huquq', 'Huquq'),
        ('Boshqaruv', 'Boshqaruv'),
        ("Til o'rganish", "Til o'rganish"),
    ]

    title = models.CharField('Nomi', max_length=160)
    description = models.TextField('Tavsif', blank=True)
    category = models.CharField('Turkum', max_length=20, choices=CATEGORIES, default='IT')
    level = models.CharField('Daraja', max_length=15, choices=LEVELS, default="Boshlang'ich")
    duration_hours = models.PositiveSmallIntegerField('Davomiyligi (soat)', default=20)
    card_color = models.CharField('Karta rangi', max_length=10, choices=CARD_COLORS, default='blue')
    image_url = models.URLField('Rasm (URL)', blank=True)
    is_active = models.BooleanField('Faol', default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Kurs'
        verbose_name_plural = 'Kurslar'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    @property
    def students_count(self):
        return self.enrollments.count()


class Enrollment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='enrollments', verbose_name='Foydalanuvchi')
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='enrollments', verbose_name='Kurs')
    progress = models.PositiveSmallIntegerField('Jarayon (%)', default=0)
    certificate = models.BooleanField('Sertifikat berilgan', default=False)
    enrolled_at = models.DateTimeField("Ro'yxatga olingan", auto_now_add=True)

    class Meta:
        verbose_name = "Kursga yozilish"
        verbose_name_plural = 'Kursga yozilishlar'
        unique_together = ['user', 'course']
        ordering = ['-enrolled_at']

    def __str__(self):
        return f'{self.user} → {self.course}'

    @property
    def is_completed(self):
        return self.progress >= 100
