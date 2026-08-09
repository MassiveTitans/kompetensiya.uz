from django.urls import path

from . import views

app_name = 'accounts'

urlpatterns = [
    path('kirish/', views.login_view, name='login'),
    path('one-id/', views.one_id_start, name='one_id'),
    path('one-id/callback/', views.one_id_callback, name='one_id_callback'),
    path('chiqish/', views.logout_view, name='logout'),
    path('profil/', views.profile_view, name='profile'),
    path('profil/tahrirlash/', views.profile_edit_view, name='profile_edit'),
]
