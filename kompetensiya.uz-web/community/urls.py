from django.urls import path

from . import views

app_name = 'community'

urlpatterns = [
    path('', views.community, name='index'),
    path('post/', views.create_post, name='create_post'),
    path('post/<int:pk>/like/', views.toggle_like, name='toggle_like'),
    path('post/<int:pk>/izoh/', views.add_comment, name='add_comment'),
    path('tadbir/<int:pk>/qatnashish/', views.join_event, name='join_event'),
]
