from django.contrib import admin
from .models import BusLine, BusStop, DensityReport, UserProfile

@admin.register(BusLine)
class BusLineAdmin(admin.ModelAdmin):
    list_display = ('name', 'route_description', 'stop_count')
    search_fields = ('name', 'route_description')
    filter_horizontal = ('stops',)

    def stop_count(self, obj):
        return obj.stops.count()
    stop_count.short_description = 'Stops'


@admin.register(BusStop)
class BusStopAdmin(admin.ModelAdmin):
    list_display = ('name', 'district', 'is_major_hub', 'latitude', 'longitude')
    search_fields = ('name', 'district')
    list_filter = ('district', 'is_major_hub')


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'points', 'trust_score', 'is_shadowbanned')
    search_fields = ('user__username',)
    list_filter = ('is_shadowbanned',)


@admin.register(DensityReport)
class DensityReportAdmin(admin.ModelAdmin):
    list_display = ('bus_line', 'user', 'density_level', 'is_active', 'reported_at')
    list_filter = ('density_level', 'is_active', 'reported_at')
    search_fields = ('bus_line__name', 'user__username')
