from django.db import transaction
from rest_framework import serializers

from .helpers import haversine_distance_meters
from .models import BusLine, BusStop, DensityReport, UserProfile


class BusStopSerializer(serializers.ModelSerializer):
    bus_lines = serializers.SlugRelatedField(
        many=True,
        read_only=True,
        slug_field='name',
    )

    class Meta:
        model = BusStop
        fields = [
            'id',
            'name',
            'latitude',
            'longitude',
            'bus_lines',
        ]


class BusLineSerializer(serializers.ModelSerializer):
    reports_count = serializers.IntegerField(read_only=True)
    stops = BusStopSerializer(many=True, read_only=True)

    class Meta:
        model = BusLine
        fields = ['id', 'name', 'route_description', 'reports_count', 'stops']


class DensityReportSerializer(serializers.ModelSerializer):
    bus_line_name = serializers.CharField(source='bus_line.name', read_only=True)
    bus_line_description = serializers.CharField(source='bus_line.route_description', read_only=True)
    bus_stop_name = serializers.CharField(source='bus_stop.name', read_only=True)
    user_username = serializers.CharField(source='user.username', read_only=True)
    user_lat = serializers.FloatField(write_only=True)
    user_lon = serializers.FloatField(write_only=True)

    class Meta:
        model = DensityReport
        fields = [
            'id',
            'bus_line',
            'bus_line_name',
            'bus_line_description',
            'bus_stop',
            'bus_stop_name',
            'user',
            'user_username',
            'density_level',
            'reported_at',
            'is_active',
            'user_lat',
            'user_lon',
        ]
        read_only_fields = ['id', 'reported_at', 'user', 'is_active']

    def validate(self, attrs):
        bus_line = attrs.get('bus_line')
        bus_stop = attrs.get('bus_stop')
        user_lat = attrs.get('user_lat')
        user_lon = attrs.get('user_lon')

        if bus_line is None:
            raise serializers.ValidationError({'bus_line': 'Bu alan zorunludur.'})
        if bus_stop is None:
            raise serializers.ValidationError({'bus_stop': 'Bu alan zorunludur.'})
        if bus_line and bus_stop and not bus_line.stops.filter(pk=bus_stop.pk).exists():
            raise serializers.ValidationError(
                {'bus_stop': 'Bu durak seçilen hatta bağlı değil.'}
            )
        if user_lat is None or user_lon is None:
            raise serializers.ValidationError(
                {'location': 'user_lat ve user_lon alanları zorunludur.'}
            )
        if bus_stop.latitude is None or bus_stop.longitude is None:
            raise serializers.ValidationError(
                {'bus_stop': 'Seçilen durağın koordinatları eksik.'}
            )

        distance_meters = haversine_distance_meters(
            user_lat,
            user_lon,
            bus_stop.latitude,
            bus_stop.longitude,
        )
        if distance_meters > 200:
            raise serializers.ValidationError(
                {'location': 'Konum doğrulaması başarısız. Duraktan 200 metreden uzaksınız.'}
            )

        return attrs

    def create(self, validated_data):
        request = self.context.get('request')
        if request is None or not request.user.is_authenticated:
            raise serializers.ValidationError({'user': 'Rapor oluşturmak için giriş yapmalısınız.'})

        validated_data.pop('user_lat', None)
        validated_data.pop('user_lon', None)

        with transaction.atomic():
            profile, _ = UserProfile.objects.select_for_update().get_or_create(
                user=request.user,
            )

            if profile.trust_score < 20 and not profile.is_shadowbanned:
                profile.is_shadowbanned = True
                profile.save(update_fields=['is_shadowbanned'])

            report = DensityReport.objects.create(
                user=request.user,
                is_active=not profile.is_shadowbanned,
                **validated_data,
            )

            if report.is_active:
                profile.points += 10
                profile.save(update_fields=['points'])

        return report


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    recent_reports = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = [
            'id',
            'user',
            'username',
            'email',
            'points',
            'trust_score',
            'is_shadowbanned',
            'recent_reports',
        ]
        read_only_fields = ['id', 'user', 'points', 'trust_score', 'is_shadowbanned', 'recent_reports']

    def get_recent_reports(self, obj):
        reports = (
            obj.user.density_reports
            .filter(is_active=True)
            .select_related('bus_line', 'bus_stop', 'user')
            .order_by('-reported_at')[:10]
        )
        return DensityReportSerializer(reports, many=True).data
