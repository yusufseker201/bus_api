from django.contrib import admin
from django.urls import path, re_path
from django.urls import include

from tracker.views import flutter_web_app

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('tracker.urls')),
    path('', flutter_web_app, name='flutter-home'),
    re_path(r'^(?P<path>.*)$', flutter_web_app, name='flutter-spa'),
]
