from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

from accounts import views as accounts_views

urlpatterns = [
    path('admin/', admin.site.urls),
    # ONE ID kabinetida ro'yxatdan o'tkazilgan callback manzili
    # (https://<domen>/one-id/callback). Ikkala shakl ham qabul qilinadi.
    path('one-id/callback', accounts_views.one_id_callback, name='one_id_callback_root'),
    path('one-id/callback/', accounts_views.one_id_callback),
    path('api/', include('api.urls')),
    path('', include('news.urls')),
    path('hisob/', include('accounts.urls')),
    path('vakansiyalar/', include('vacancies.urls')),
    path('kurslar/', include('courses.urls')),
    path('baholash/', include('assessments.urls')),
    path('hamjamiyat/', include('community.urls')),
    path('faoliyat/', include('performance.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

admin.site.site_header = 'Kompetensiya.uz boshqaruv paneli'
admin.site.site_title = 'Kompetensiya.uz'
admin.site.index_title = 'Istiqbolli Kadrlar platformasi'
