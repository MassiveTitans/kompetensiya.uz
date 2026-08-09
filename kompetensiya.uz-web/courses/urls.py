from django.urls import path

from . import views

app_name = 'courses'

urlpatterns = [
    path('', views.course_list, name='list'),
    path('<int:pk>/yozilish/', views.enroll, name='enroll'),
    path('kurslarim/', views.my_courses, name='my_courses'),
]
