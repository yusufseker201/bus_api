from pathlib import Path
import mimetypes

from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from django.http import FileResponse, Http404
from django.db.models import Count, Prefetch, Q
from django.views.decorators.http import require_GET
from django.views.decorators.csrf import csrf_exempt  # CSRF muafiyeti için eklendi
from django.utils.decorators import method_decorator  # Class-based view'lar için eklendi
from rest_framework.authtoken.models import Token
from rest_framework import permissions, status, viewsets
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import serializers
from rest_framework.authentication import TokenAuthentication, SessionAuthentication

from .models import BusLine, BusStop, DensityReport, UserProfile
from .serializers import BusLineSerializer, BusStopSerializer, DensityReportSerializer, UserProfileSerializer
from .throttles import UserReportRateThrottle


@require_GET
def flutter_web_app(request, path=''):
    """
    Serve the built Flutter web app from the Django root.
    """
    web_dir = Path(settings.FLUTTER_WEB_DIR)
    if not web_dir.exists():
        raise Http404(
            'Flutter web build not found. Run `flutter build web` in flutter_frontend first.'
        )

    requested = path.strip('/')
    file_path = web_dir / requested if requested else web_dir / 'index.html'

    if file_path.is_dir():
        file_path = file_path / 'index.html'

    if file_path.exists() and file_path.is_file():
        content_type, encoding = mimetypes.guess_type(str(file_path))
        response = FileResponse(
            open(file_path, 'rb'),
            content_type=content_type or 'application/octet-stream',
        )
        _apply_no_cache_headers(response, encoding=encoding)
        _apply_dev_site_data_headers(response, requested)
        return response

    index_path = web_dir / 'index.html'
    if index_path.exists():
        response = FileResponse(open(index_path, 'rb'), content_type='text/html')
        _apply_no_cache_headers(response)
        _apply_dev_site_data_headers(response, requested)
        return response

    raise Http404('Flutter web entrypoint not found.')


def _apply_no_cache_headers(response, encoding=None):
    if encoding:
        response['Content-Encoding'] = encoding
    response['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    response['Pragma'] = 'no-cache'
    response['Expires'] = '0'


def _apply_dev_site_data_headers(response, requested_path):
    if not settings.DEBUG:
        return

    if requested_path in {'', 'index.html', 'flutter_bootstrap.js', 'flutter_service_worker.js'}:
        response['Clear-Site-Data'] = '"cache"'


class LoginSerializer(serializers.Serializer):
    email = serializers.CharField()
    password = serializers.CharField(trim_whitespace=False)


# Web testlerinde ve Flutter isteklerinde CSRF engeline takılmamak için muaf tutuyoruz
@method_decorator(csrf_exempt, name='dispatch')
class LoginView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []  # Login olurken session kontrolünü tamamen kapat

    def post(self, request, *args, **kwargs):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        identifier = serializer.validated_data['email']
        password = serializer.validated_data['password']

        user = authenticate(request, username=identifier, password=password)
        if user is None:
            User = get_user_model()
            matched_user = User.objects.filter(email__iexact=identifier).first()

            if matched_user is not None:
                user = authenticate(request, username=matched_user.get_username(), password=password)

        if user is None:
            return Response(
                {'detail': 'Geçersiz e-posta/kullanıcı adı veya şifre.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {
                'token': token.key,
                'user_id': user.id,
            },
            status=status.HTTP_200_OK,
        )


class BusLineViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = BusLine.objects.prefetch_related('stops').annotate(
        reports_count=Count('reports', filter=Q(reports__is_active=True))
    )
    serializer_class = BusLineSerializer
    permission_classes = [permissions.AllowAny]
    authentication_classes = []  # Herkesin erişebilmesi için auth filtrelerini temizle


class BusStopViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = BusStop.objects.prefetch_related('bus_lines')
    serializer_class = BusStopSerializer
    permission_classes = [permissions.AllowAny]
    authentication_classes = []  # Herkesin erişebilmesi için auth filtrelerini temizle


@method_decorator(csrf_exempt, name='dispatch')
class DensityReportViewSet(viewsets.ModelViewSet):
    http_method_names = ['get', 'post', 'head', 'options']
    serializer_class = DensityReportSerializer
    # Varsayılan izni AllowAny yapıyoruz ki GET istekleri (listeleme) serbest olsun
    permission_classes = [permissions.AllowAny]
    # Sadece Token tabanlı doğrulamayı önceliklendiriyoruz, Session tabanlı CSRF kontrolünü eziyoruz
    authentication_classes = [TokenAuthentication]

    def get_queryset(self):
        return DensityReport.objects.select_related('bus_line', 'bus_stop', 'user').filter(
            is_active=True,
        )

    def get_permissions(self):
        # Sadece rapor gönderirken (POST - create veya submit) giriş zorunlu olsun
        if self.action in {'create', 'submit'}:
            return [permissions.IsAuthenticated()]
        # Listeleme (GET) işlemlerinde herkese izin ver
        return [permissions.AllowAny()]

    def get_throttles(self):
        if self.action in {'create', 'submit'}:
            return [UserReportRateThrottle()]
        return []

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        report = serializer.save()
        output_serializer = self.get_serializer(report)
        return Response(output_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='submit')
    def submit(self, request, *args, **kwargs):
        return self.create(request, *args, **kwargs)


class UserProfileViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = UserProfile.objects.select_related('user')
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [TokenAuthentication]

    def get_queryset(self):
        active_reports = DensityReport.objects.filter(is_active=True).select_related(
            'bus_line',
            'bus_stop',
            'user',
        )
        return UserProfile.objects.select_related('user').prefetch_related(
            Prefetch('user__density_reports', queryset=active_reports),
        )

    @action(detail=False, methods=['get'])
    def me(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)