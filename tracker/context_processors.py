from django.urls import NoReverseMatch, reverse

from .live_reports import active_report_count, build_live_report_snapshot


def live_admin_metrics(request):
    if not request.user.is_authenticated or not request.user.is_staff:
        return {}

    try:
        index_url = reverse('admin:index')
        dashboard_url = reverse('admin:live_reports_dashboard')
        data_url = reverse('admin:live_reports_data')
    except NoReverseMatch:
        return {}

    should_preload_snapshot = request.path in {index_url, dashboard_url}
    snapshot = build_live_report_snapshot(limit=8) if should_preload_snapshot else None

    return {
        'live_admin_metrics': {
            'active_report_count': snapshot['count'] if snapshot else active_report_count(),
            'dashboard_url': dashboard_url,
            'data_url': data_url,
            'poll_interval_ms': 15000,
            'updated_at': snapshot['updated_at'] if snapshot else '',
            'reports': snapshot['reports'] if snapshot else [],
        }
    }
