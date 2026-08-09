from django.urls import path

from . import views

app_name = 'api'

urlpatterns = [
    # Autentifikatsiya (ONE ID)
    path('auth/one-id/', views.one_id_config, name='one_id_config'),
    path('auth/one-id/exchange/', views.one_id_exchange, name='one_id_exchange'),
    path('auth/logout/', views.logout, name='logout'),
    path('me/', views.me, name='me'),

    # Kontent
    path('news/', views.news_list, name='news'),
    path('banners/', views.banner_list, name='banners'),
    path('vacancies/', views.vacancy_list, name='vacancies'),
    path('vacancies/fields/', views.vacancy_fields, name='vacancy_fields'),
    path('vacancies/<int:pk>/apply/', views.vacancy_apply, name='vacancy_apply'),
    path('courses/', views.course_list, name='courses'),
    path('courses/filters/', views.course_filters, name='course_filters'),
    path('courses/<int:pk>/enroll/', views.course_enroll, name='course_enroll'),

    # Baholash
    path('assessments/', views.assessment_list, name='assessments'),
    path('assessments/<int:pk>/questions/', views.assessment_questions, name='assessment_questions'),
    path('assessments/<int:pk>/submit/', views.assessment_submit, name='assessment_submit'),

    # Hamjamiyat
    path('community/posts/', views.post_list, name='posts'),
    path('community/posts/create/', views.post_create, name='post_create'),
    path('community/posts/<int:pk>/like/', views.post_like, name='post_like'),
    path('community/posts/<int:pk>/comment/', views.post_comment, name='post_comment'),
    path('community/events/', views.event_list, name='events'),
    path('rating/', views.rating, name='rating'),

    # Faoliyat
    path('kpi/', views.kpi, name='kpi'),
    path('attendance/', views.attendance, name='attendance'),
    path('attendance/gps/', views.attendance_gps, name='attendance_gps'),
    path('attendance/qr/', views.attendance_qr, name='attendance_qr'),
    path('attendance/events/', views.event_attendance_list, name='event_attendance'),
]
