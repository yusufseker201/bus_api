from pathlib import Path
import mimetypes

from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import FileResponse, Http404
from django.db.models import Count, Prefetch, Q
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from django.utils.text import slugify
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


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(trim_whitespace=False)
    confirm_password = serializers.CharField(trim_whitespace=False)

    def validate_email(self, value):
        normalized = value.strip().lower()
        if not normalized:
            raise serializers.ValidationError('Bu alan zorunludur.')
        return normalized

    def validate(self, attrs):
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError(
                {'confirm_password': 'Şifreler eşleşmiyor.'}
            )

        try:
            validate_password(attrs['password'])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({'password': list(exc.messages)})

        return attrs


class PasswordResetRequestSerializer(serializers.Serializer):
    identifier = serializers.CharField()

    def validate_identifier(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Bu alan zorunludur.')
        return value


class PasswordResetConfirmSerializer(serializers.Serializer):
    uid = serializers.CharField()
    token = serializers.CharField()
    new_password = serializers.CharField(trim_whitespace=False, write_only=True)
    confirm_password = serializers.CharField(trim_whitespace=False, write_only=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError(
                {'confirm_password': 'Şifreler eşleşmiyor.'}
            )
        return attrs


def _find_user_for_password_reset(identifier):
    User = get_user_model()
    return User.objects.filter(
        Q(email__iexact=identifier) | Q(username__iexact=identifier)
    ).first()


def _build_unique_username(email):
    User = get_user_model()
    local_part = email.split('@', 1)[0]
    base = slugify(local_part) or 'user'
    candidate = base[:150]
    suffix = 1

    while User.objects.filter(username__iexact=candidate).exists():
        suffix_text = f'-{suffix}'
        trimmed_base = base[: max(1, 150 - len(suffix_text))]
        candidate = f'{trimmed_base}{suffix_text}'
        suffix += 1

    return candidate


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


@method_decorator(csrf_exempt, name='dispatch')
class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, *args, **kwargs):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        User = get_user_model()
        if User.objects.filter(email__iexact=email).exists():
            return Response(
                {'email': 'Bu e-posta ile kayıtlı bir hesap zaten var.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        username = _build_unique_username(email)
        User.objects.create_user(
            username=username,
            email=email,
            password=password,
        )

        return Response(
            {
                'detail': 'Hesabın oluşturuldu. Şimdi giriş yapabilirsin.',
                'email': email,
            },
            status=status.HTTP_201_CREATED,
        )


@method_decorator(csrf_exempt, name='dispatch')
class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, *args, **kwargs):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        identifier = serializer.validated_data['identifier']
        user = _find_user_for_password_reset(identifier)
        if user is None:
            return Response(
                {'detail': 'Bu e-posta/kullanıcı adına sahip hesap bulunamadı.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        uid = urlsafe_base64_encode(force_bytes(user.pk))
        token = default_token_generator.make_token(user)

        return Response(
            {
                'detail': 'Şifre sıfırlama bilgileri hazır.',
                'uid': uid,
                'token': token,
            },
            status=status.HTTP_200_OK,
        )


@method_decorator(csrf_exempt, name='dispatch')
class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, *args, **kwargs):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        uid = serializer.validated_data['uid']
        token = serializer.validated_data['token']
        new_password = serializer.validated_data['new_password']

        try:
            user_pk = force_str(urlsafe_base64_decode(uid))
        except (TypeError, ValueError, OverflowError):
            return Response(
                {'detail': 'Geçersiz sıfırlama bilgisi.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        User = get_user_model()
        user = User.objects.filter(pk=user_pk).first()
        if user is None or not default_token_generator.check_token(user, token):
            return Response(
                {'detail': 'Sıfırlama bağlantısı geçersiz veya süresi dolmuş.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            validate_password(new_password, user=user)
        except DjangoValidationError as exc:
            return Response(
                {'new_password': list(exc.messages)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(new_password)
        user.save(update_fields=['password'])
        Token.objects.filter(user=user).delete()

        return Response(
            {'detail': 'Şifren güncellendi. Yeni şifrenle giriş yapabilirsin.'},
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
    # Okuma isteklerinde token doğrulamasını kapatıyoruz; yazma isteklerinde açıyoruz.
    authentication_classes = []

    def initialize_request(self, request, *args, **kwargs):
        if request.method in permissions.SAFE_METHODS:
            self.authentication_classes = []
        else:
            self.authentication_classes = [TokenAuthentication]
        return super().initialize_request(request, *args, **kwargs)

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
