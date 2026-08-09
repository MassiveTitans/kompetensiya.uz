from django.urls import path

from . import views

app_name = 'news'

urlpatterns = [
    path('', views.landing, name='landing'),
    path('asosiy/', views.home, name='home'),
    path('yangilik/<int:pk>/', views.news_detail, name='detail'),
]
