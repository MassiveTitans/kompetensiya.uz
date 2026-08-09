from django.urls import path

from . import views

app_name = 'assessments'

urlpatterns = [
    path('', views.assessment_list, name='list'),
    path('<int:pk>/test/', views.take_test, name='take_test'),
    path('natija/<int:pk>/', views.result_view, name='result'),
]
