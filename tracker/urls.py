from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    BusLineViewSet,
    BusStopViewSet,
    DensityReportViewSet,
    LoginView,
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
]
urlpatterns += router.urls
