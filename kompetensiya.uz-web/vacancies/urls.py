from django.urls import path

from . import views

app_name = 'vacancies'

urlpatterns = [
    path('', views.vacancy_list, name='list'),
    path('<int:pk>/ariza/', views.apply, name='apply'),
    path('arizalarim/', views.my_applications, name='my_applications'),
]
