from datetime import timedelta

from django.db.models import Q
from django.urls import reverse
from django.utils import formats, timezone

from .models import DensityReport


LIVE_REPORT_LOOKBACK = timedelta(hours=1)


def live_report_cutoff():
    return timezone.now() - LIVE_REPORT_LOOKBACK


def live_reports_queryset(limit=None):
    queryset = (
        DensityReport.objects.select_related('bus_line', 'bus_stop', 'user')
        .filter(Q(reported_at__gte=live_report_cutoff()) | Q(is_active=True))
        .order_by('-reported_at')
    )
    if limit is not None:
        return queryset[:limit]
    return queryset


def active_report_count():
    return DensityReport.objects.filter(
        Q(reported_at__gte=live_report_cutoff()) | Q(is_active=True)
    ).count()


def serialize_live_report(report):
    full_name = report.user.get_full_name().strip() if report.user else ''
    return {
        'id': report.id,
        'bus_line': report.bus_line.name,
        'bus_stop': report.bus_stop.name if report.bus_stop else '-',
        'district': report.bus_stop.district if report.bus_stop else '',
        'density_code': report.density_level,
        'density_label': report.get_density_level_display(),
        'density_class': report.density_level.lower(),
        'username': report.user.username if report.user else '-',
        'full_name': full_name or '-',
        'is_active': report.is_active,
        'reported_at': formats.date_format(
            timezone.localtime(report.reported_at),
            'd.m.Y H:i:s',
            use_l10n=True,
        ),
        'change_url': reverse('admin:tracker_densityreport_change', args=[report.pk]),
    }


def build_live_report_snapshot(limit=20):
    reports = [serialize_live_report(report) for report in live_reports_queryset(limit=limit)]
    return {
        'count': active_report_count(),
        'reports': reports,
        'updated_at': formats.date_format(
            timezone.localtime(timezone.now()),
            'd.m.Y H:i:s',
            use_l10n=True,
        ),
    }
