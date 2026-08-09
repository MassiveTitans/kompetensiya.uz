from django.contrib.auth.models import User
from django.db import models

from news.models import CARD_COLORS


class Assessment(models.Model):
    KINDS = [
        ('skill', "Ko'nikma baholash"),
        ('psych', 'Psixologik test'),
    ]
    LEVELS = [
        ("Boshlang'ich", "Boshlang'ich"),
        ("O'rta", "O'rta"),
        ('Yuqori', 'Yuqori'),
        ('Umumiy', 'Umumiy'),
    ]
    ICONS = [
        ('code', 'Kod'),
        ('analytics', 'Tahlil'),
        ('language', 'Til'),
        ('design', 'Dizayn'),
        ('management', 'Boshqaruv'),
        ('brain', 'Aql'),
        ('emotion', 'Hissiyot'),
        ('stress', 'Stress'),
        ('leadership', 'Yetakchilik'),
        ('motivation', 'Motivatsiya'),
    ]

    title = models.CharField('Nomi', max_length=160)
    kind = models.CharField('Turi', max_length=5, choices=KINDS, default='skill')
    icon = models.CharField('Belgi', max_length=12, choices=ICONS, default='code')
    color = models.CharField('Rang', max_length=10, choices=CARD_COLORS, default='blue')
    duration_minutes = models.PositiveSmallIntegerField('Davomiyligi (daqiqa)', default=15)
    level = models.CharField('Daraja', max_length=15, choices=LEVELS, default='Umumiy')
    is_active = models.BooleanField('Faol', default=True)
    order = models.PositiveSmallIntegerField('Tartib', default=0)

    class Meta:
        verbose_name = 'Test'
        verbose_name_plural = 'Testlar'
        ordering = ['order', 'id']

    def __str__(self):
        return self.title

    @property
    def question_count(self):
        return self.questions.count()


class Question(models.Model):
    assessment = models.ForeignKey(Assessment, on_delete=models.CASCADE, related_name='questions', verbose_name='Test')
    text = models.TextField('Savol')
    order = models.PositiveSmallIntegerField('Tartib', default=0)

    class Meta:
        verbose_name = 'Savol'
        verbose_name_plural = 'Savollar'
        ordering = ['order', 'id']

    def __str__(self):
        return self.text[:60]


class Choice(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='choices', verbose_name='Savol')
    text = models.CharField('Javob', max_length=250)
    is_correct = models.BooleanField("To'g'ri javob", default=False)
    weight = models.PositiveSmallIntegerField('Ball (psixologik test uchun)', default=0)

    class Meta:
        verbose_name = 'Javob varianti'
        verbose_name_plural = 'Javob variantlari'

    def __str__(self):
        return self.text[:60]


class TestResult(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='test_results', verbose_name='Foydalanuvchi')
    assessment = models.ForeignKey(Assessment, on_delete=models.CASCADE, related_name='results', verbose_name='Test')
    score = models.FloatField('Natija (%)', default=0)
    correct_answers = models.PositiveSmallIntegerField("To'g'ri javoblar", default=0)
    total_questions = models.PositiveSmallIntegerField('Jami savollar', default=0)
    completed_at = models.DateTimeField('Yakunlangan', auto_now_add=True)

    class Meta:
        verbose_name = 'Test natijasi'
        verbose_name_plural = 'Test natijalari'
        ordering = ['-completed_at']

    def __str__(self):
        return f'{self.user} — {self.assessment}: {self.score:.0f}%'
