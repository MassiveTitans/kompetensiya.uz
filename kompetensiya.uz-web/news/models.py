from django.db import models

CARD_COLORS = [
    ('blue', "Ko'k"),
    ('orange', "To'q sariq"),
    ('dark', 'Qora'),
    ('green', 'Yashil'),
    ('purple', 'Binafsha'),
    ('teal', 'Moviy-yashil'),
    ('red', 'Qizil'),
    ('indigo', 'Indigo'),
]


class News(models.Model):
    CATEGORY_CHOICES = [
        ("E'lon", "E'lon"),
        ('Yangilik', 'Yangilik'),
        ('Yangilanish', 'Yangilanish'),
        ('Tadbir', 'Tadbir'),
        ('Kurs', 'Kurs'),
    ]

    title = models.CharField('Sarlavha', max_length=200)
    body = models.TextField('Matn', blank=True)
    category = models.CharField('Turkum', max_length=20, choices=CATEGORY_CHOICES, default='Yangilik')
    card_color = models.CharField('Karta rangi', max_length=10, choices=CARD_COLORS, default='blue')
    image_url = models.URLField('Rasm (URL)', blank=True)
    is_urgent = models.BooleanField('Muhim', default=False)
    is_published = models.BooleanField('Chop etilgan', default=True)
    created_at = models.DateTimeField('Yaratilgan', auto_now_add=True)

    class Meta:
        verbose_name = 'Yangilik'
        verbose_name_plural = 'Yangiliklar'
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class Banner(models.Model):
    title = models.CharField('Sarlavha', max_length=120)
    subtitle = models.CharField('Qisqacha', max_length=200, blank=True)
    image_url = models.URLField('Rasm (URL)', blank=True)
    link = models.CharField('Havola', max_length=200, blank=True)
    color = models.CharField('Rang', max_length=10, choices=CARD_COLORS, default='blue')
    order = models.PositiveSmallIntegerField('Tartib', default=0)
    is_active = models.BooleanField('Faol', default=True)

    class Meta:
        verbose_name = 'Banner'
        verbose_name_plural = 'Bannerlar'
        ordering = ['order']

    def __str__(self):
        return self.title
