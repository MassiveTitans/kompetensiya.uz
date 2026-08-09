from django.urls import path

from . import views

app_name = 'performance'

urlpatterns = [
    path('davomat/', views.attendance, name='attendance'),
    path('davomat/gps/', views.gps_check_in, name='gps_check_in'),
    path('davomat/qr/', views.qr_check_in, name='qr_check_in'),
    path('kpi/', views.kpi, name='kpi'),
]
