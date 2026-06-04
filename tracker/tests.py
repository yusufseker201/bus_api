import json
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework.authtoken.models import Token

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


@override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1'])
class DensityReportApiTests(TestCase):
    def setUp(self):
        self.bus_stop = BusStop.objects.create(
            name='Test Durak',
            district='Merkez',
            latitude=37.5753,
            longitude=36.9228,
        )
        self.bus_line = BusLine.objects.create(
            name='T-1',
            route_description='Test Hattı',
        )
        self.bus_line.stops.add(self.bus_stop)
        self.report = DensityReport.objects.create(
            bus_line=self.bus_line,
            bus_stop=self.bus_stop,
            density_level='GREEN',
        )

    def test_list_ignores_invalid_token_header(self):
        response = self.client.get(
            reverse('densityreport-list'),
            HTTP_AUTHORIZATION='Token invalid-token',
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(len(payload), 1)
        self.assertEqual(payload[0]['id'], self.report.id)

    def test_create_still_requires_a_valid_token(self):
        response = self.client.post(
            reverse('densityreport-list'),
            data=json.dumps(
                {
                    'bus_line': self.bus_line.id,
                    'bus_stop': self.bus_stop.id,
                    'density_level': 'YELLOW',
                    'user_lat': self.bus_stop.latitude,
                    'user_lon': self.bus_stop.longitude,
                }
            ),
            content_type='application/json',
            HTTP_AUTHORIZATION='Token invalid-token',
        )

        self.assertEqual(response.status_code, 401)


@override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1'])
class DensityReportAdminExportTests(TestCase):
    def setUp(self):
        user_model = get_user_model()
        self.admin_user = user_model.objects.create_superuser(
            username='admin-export',
            email='admin-export@example.com',
            password='secret123',
        )
        self.reporter = user_model.objects.create_user(
            username='reporter-export',
            email='reporter-export@example.com',
            password='secret123',
        )
        self.bus_stop = BusStop.objects.create(
            name='Export Durak',
            district='Merkez',
            latitude=37.5753,
            longitude=36.9228,
        )
        self.bus_line = BusLine.objects.create(
            name='E-1',
            route_description='Export Hatti',
        )
        self.bus_line.stops.add(self.bus_stop)
        self.report = DensityReport.objects.create(
            bus_line=self.bus_line,
            bus_stop=self.bus_stop,
            user=self.reporter,
            density_level='RED',
        )

    def test_download_csv_button_exports_reports(self):
        self.client.force_login(self.admin_user)

        response = self.client.get(reverse('admin:tracker_densityreport_download_csv'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response['Content-Disposition'],
            'attachment; filename="yogunluk_raporlari.csv"',
        )
        payload = response.content.decode('utf-8-sig')
        self.assertIn('Otobus Hatti', payload)
        self.assertIn(self.bus_line.name, payload)
        self.assertIn(self.reporter.username, payload)
        self.assertIn(str(self.report.id), payload)


@override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1'])
class PasswordResetApiTests(TestCase):
    def setUp(self):
        self.user_model = get_user_model()
        self.user = self.user_model.objects.create_user(
            username='forgot-user',
            email='forgot@example.com',
            password='old-pass123',
        )
        self.old_token = Token.objects.create(user=self.user)

    def test_request_returns_reset_payload(self):
        response = self.client.post(
            reverse('password-reset-request'),
            data=json.dumps({'identifier': 'forgot@example.com'}),
            content_type='application/json',
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertIn('uid', payload)
        self.assertIn('token', payload)
        self.assertEqual(payload['detail'], 'Şifre sıfırlama bilgileri hazır.')

    def test_confirm_updates_password_and_invalidates_existing_token(self):
        request_response = self.client.post(
            reverse('password-reset-request'),
            data=json.dumps({'identifier': 'forgot@example.com'}),
            content_type='application/json',
        )
        payload = request_response.json()

        response = self.client.post(
            reverse('password-reset-confirm'),
            data=json.dumps(
                {
                    'uid': payload['uid'],
                    'token': payload['token'],
                    'new_password': 'New-pass123!',
                    'confirm_password': 'New-pass123!',
                }
            ),
            content_type='application/json',
        )

        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('New-pass123!'))
        self.assertFalse(Token.objects.filter(user=self.user).exists())

        login_response = self.client.post(
            reverse('login'),
            data=json.dumps(
                {
                    'email': 'forgot@example.com',
                    'password': 'New-pass123!',
                }
            ),
            content_type='application/json',
        )
        self.assertEqual(login_response.status_code, 200)
