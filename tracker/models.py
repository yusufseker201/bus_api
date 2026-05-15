from django.contrib.auth.models import User
from django.db import models


class BusLine(models.Model):
    name = models.CharField(max_length=50, unique=True)
    route_description = models.CharField(max_length=200)
    stops = models.ManyToManyField(
        'BusStop',
        related_name='bus_lines',
        blank=True,
    )

    class Meta:
        ordering = ['name']

    def __str__(self) -> str:
        return self.name


class BusStop(models.Model):
    name = models.CharField(max_length=100, unique=True)
    district = models.CharField(max_length=100, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    is_major_hub = models.BooleanField(default=False)

    class Meta:
        ordering = ['name']

    def __str__(self) -> str:
        return self.name


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    points = models.IntegerField(default=0)
    trust_score = models.IntegerField(default=100)
    is_shadowbanned = models.BooleanField(default=False)

    class Meta:
        ordering = ['-points', 'user__username']

    def __str__(self) -> str:
        return f'{self.user.username} profile'


class DensityReport(models.Model):
    DENSITY_CHOICES = [
        ('GREEN', 'Empty'),
        ('YELLOW', 'Moderate'),
        ('RED', 'Crowded'),
        ('BLACK', 'Full'),
    ]

    bus_line = models.ForeignKey(BusLine, on_delete=models.PROTECT, related_name='reports')
    bus_stop = models.ForeignKey(
        BusStop,
        on_delete=models.PROTECT,
        related_name='reports',
        null=True,
        blank=True,
    )
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='density_reports',
    )
    density_level = models.CharField(max_length=10, choices=DENSITY_CHOICES)
    reported_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['-reported_at']
        indexes = [
            models.Index(fields=['bus_line', 'bus_stop']),
            models.Index(fields=['reported_at']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self) -> str:
        stop_name = self.bus_stop.name if self.bus_stop else 'Unknown stop'
        return f'{self.bus_line.name} @ {stop_name} - {self.get_density_level_display()}'
