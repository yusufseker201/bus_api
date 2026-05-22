from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone

from .live_reports import active_report_count, build_live_report_snapshot
from .models import BusLine, BusStop, DensityReport


@override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1'])
class LiveAdminDashboardTests(TestCase):
    def setUp(self):
        user_model = get_user_model()
        self.admin_user = user_model.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='secret123',
        )
        self.reporter = user_model.objects.create_user(
            username='reporter',
            email='reporter@example.com',
            password='secret123',
            first_name='Can',
            last_name='Operator',
        )
        self.bus_stop = BusStop.objects.create(
            name='Trabzon Bulvari',
            district='Dulkadiroglu',
            latitude=37.5753,
            longitude=36.9228,
        )
        self.bus_line = BusLine.objects.create(
            name='B-14',
            route_description='Otogar - Universite',
        )
        self.bus_line.stops.add(self.bus_stop)

        now = timezone.now()
        self.recent_active_report = self._create_report(
            density_level='BLACK',
            is_active=True,
            reported_at=now - timedelta(minutes=10),
        )
        self.recent_inactive_report = self._create_report(
            density_level='RED',
            is_active=False,
            reported_at=now - timedelta(minutes=35),
        )
        self.old_active_report = self._create_report(
            density_level='YELLOW',
            is_active=True,
            reported_at=now - timedelta(hours=3),
        )
        self.old_inactive_report = self._create_report(
            density_level='GREEN',
            is_active=False,
            reported_at=now - timedelta(hours=4),
        )

    def _create_report(self, density_level, is_active, reported_at):
        report = DensityReport.objects.create(
            bus_line=self.bus_line,
            bus_stop=self.bus_stop,
            user=self.reporter,
            density_level=density_level,
            is_active=is_active,
        )
        DensityReport.objects.filter(pk=report.pk).update(reported_at=reported_at)
        report.refresh_from_db()
        return report

    def test_active_report_count_uses_recent_or_active_logic(self):
        self.assertEqual(active_report_count(), 3)

        snapshot = build_live_report_snapshot(limit=10)
        self.assertEqual(snapshot['count'], 3)
        self.assertEqual(
            [report['id'] for report in snapshot['reports']],
            [
                self.recent_active_report.id,
                self.recent_inactive_report.id,
                self.old_active_report.id,
            ],
        )

    def test_admin_index_renders_live_snapshot_without_waiting_for_poll(self):
        self.client.force_login(self.admin_user)

        response = self.client.get(reverse('admin:index'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Canli Bildirim Sayaci')
        self.assertContains(response, self.bus_line.name)
        self.assertContains(response, self.reporter.get_full_name())
        self.assertEqual(response.context['live_admin_metrics']['active_report_count'], 3)
        self.assertEqual(len(response.context['live_admin_metrics']['reports']), 3)

    def test_live_reports_data_endpoint_returns_dynamic_payload(self):
        self.client.force_login(self.admin_user)

        response = self.client.get(reverse('admin:live_reports_data'))

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload['count'], 3)
        self.assertEqual(len(payload['reports']), 3)
        self.assertNotIn(
            self.old_inactive_report.id,
            [report['id'] for report in payload['reports']],
        )
        self.assertEqual(payload['reports'][0]['full_name'], self.reporter.get_full_name())

    def test_live_reports_dashboard_page_is_available_in_admin(self):
        self.client.force_login(self.admin_user)

        response = self.client.get(reverse('admin:live_reports_dashboard'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Anlik Rapor Akisi')
        self.assertContains(response, self.bus_stop.name)
