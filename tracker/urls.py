from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    BusLineViewSet,
    BusStopViewSet,
    DensityReportViewSet,
    LoginView,
    RegisterView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    UserProfileViewSet,
)

router = DefaultRouter()
router.register(r'bus-lines', BusLineViewSet, basename='busline')
router.register(r'bus-stops', BusStopViewSet, basename='busstop')
router.register(r'reports', DensityReportViewSet, basename='densityreport')
router.register(r'profiles', UserProfileViewSet, basename='userprofile')

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('auth/login/', LoginView.as_view(), name='auth-login'),
    path('register/', RegisterView.as_view(), name='register'),
    path('auth/register/', RegisterView.as_view(), name='auth-register'),
    path(
        'auth/password-reset/request/',
        PasswordResetRequestView.as_view(),
        name='password-reset-request',
    ),
    path(
        'auth/password-reset/confirm/',
        PasswordResetConfirmView.as_view(),
        name='password-reset-confirm',
    ),
]
urlpatterns += router.urls
