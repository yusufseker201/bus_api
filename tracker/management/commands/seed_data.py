from decimal import Decimal

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from tracker.models import BusLine, BusStop, DensityReport, UserProfile


class Command(BaseCommand):
    help = 'Seed Kahramanmaraş-specific bus lines, stops, and sample density reports.'

    def handle(self, *args, **options):
        DensityReport.objects.all().delete()
        BusLine.objects.all().delete()
        BusStop.objects.all().delete()
        stops = self._seed_stops()
        lines = self._seed_lines(stops)
        demo_user = self._seed_demo_user()
        created_reports = self._seed_reports(lines, stops, demo_user)

        self.stdout.write(self.style.SUCCESS(
            f'Seeded {len(lines)} lines, {len(stops)} stops, and {created_reports} demo reports.'
        ))

    def _seed_stops(self):
        stop_specs = [
            {
                'name': 'KSÜ Avşar Kampüsü',
                'district': 'Onikişubat',
                'latitude': Decimal('37.575420'),
                'longitude': Decimal('36.930610'),
                'is_major_hub': True,
            },
            {
                'name': 'Piazza AVM',
                'district': 'Onikişubat',
                'latitude': Decimal('37.565940'),
                'longitude': Decimal('36.937480'),
                'is_major_hub': True,
            },
            {
                'name': 'Ulu Cami',
                'district': 'Dulkadiroğlu',
                'latitude': Decimal('37.581220'),
                'longitude': Decimal('36.927910'),
                'is_major_hub': True,
            },
            {
                'name': 'Binevler',
                'district': 'Onikişubat',
                'latitude': Decimal('37.553880'),
                'longitude': Decimal('36.945820'),
                'is_major_hub': True,
            },
            {
                'name': 'Şelale Park',
                'district': 'Onikişubat',
                'latitude': Decimal('37.572510'),
                'longitude': Decimal('36.950410'),
                'is_major_hub': False,
            },
            {
                'name': 'Kahramanmaraş Otogarı',
                'district': 'Onikişubat',
                'latitude': Decimal('37.585140'),
                'longitude': Decimal('36.955180'),
                'is_major_hub': True,
            },
            {
                'name': 'Tekerek Yolu',
                'district': 'Onikişubat',
                'latitude': Decimal('37.560930'),
                'longitude': Decimal('36.944180'),
                'is_major_hub': False,
            },
            {
                'name': 'Hasancıklı',
                'district': 'Onikişubat',
                'latitude': Decimal('37.545760'),
                'longitude': Decimal('36.941230'),
                'is_major_hub': False,
            },
            {
                'name': 'Kuyumcukent',
                'district': 'Onikişubat',
                'latitude': Decimal('37.567400'),
                'longitude': Decimal('36.942500'),
                'is_major_hub': False,
            },
            {
                'name': 'Sanayi',
                'district': 'Onikişubat',
                'latitude': Decimal('37.571820'),
                'longitude': Decimal('36.946650'),
                'is_major_hub': False,
            },
            {
                'name': 'Çocuk Hastanesi',
                'district': 'Onikişubat',
                'latitude': Decimal('37.568880'),
                'longitude': Decimal('36.940160'),
                'is_major_hub': True,
            },
            {
                'name': 'Doğukent',
                'district': 'Dulkadiroğlu',
                'latitude': Decimal('37.551240'),
                'longitude': Decimal('36.960420'),
                'is_major_hub': True,
            },
            {
                'name': 'Vali Saim Çotur',
                'district': 'Dulkadiroğlu',
                'latitude': Decimal('37.548090'),
                'longitude': Decimal('36.967540'),
                'is_major_hub': False,
            },
            {
                'name': 'EXPO Alanı',
                'district': 'Dulkadiroğlu',
                'latitude': Decimal('37.544180'),
                'longitude': Decimal('36.973060'),
                'is_major_hub': False,
            },
            {
                'name': 'NFK Şehir Hastanesi',
                'district': 'Dulkadiroğlu',
                'latitude': Decimal('37.557930'),
                'longitude': Decimal('36.971780'),
                'is_major_hub': True,
            },
            {
                'name': 'Güneşevler',
                'district': 'Onikişubat',
                'latitude': Decimal('37.548520'),
                'longitude': Decimal('36.949540'),
                'is_major_hub': False,
            },
            {
                'name': 'Üngüt',
                'district': 'Onikişubat',
                'latitude': Decimal('37.547910'),
                'longitude': Decimal('36.936220'),
                'is_major_hub': False,
            },
            {
                'name': 'Adliye',
                'district': 'Dulkadiroğlu',
                'latitude': Decimal('37.582610'),
                'longitude': Decimal('36.922430'),
                'is_major_hub': True,
            },
            {
                'name': 'Kahramanmaraş Büyükşehir Belediyesi',
                'district': 'Onikişubat',
                'latitude': Decimal('37.568390'),
                'longitude': Decimal('36.934810'),
                'is_major_hub': True,
            },
        ]

        stops = []
        for spec in stop_specs:
            stop, _ = BusStop.objects.get_or_create(
                name=spec['name'],
                defaults=spec,
            )
            stops.append(stop)
        return stops

    def _seed_lines(self, stops):
        stop_lookup = {stop.name: stop for stop in stops}

        line_specs = [
            {
                'name': 'H24',
                'route_description': 'Kahramanmaraş Otogarı - Piazza AVM - Binevler - Ulu Cami - KSÜ Avşar Kampüsü',
                'stop_names': [
                    'Kahramanmaraş Otogarı',
                    'Piazza AVM',
                    'Şelale Park',
                    'Binevler',
                    'Ulu Cami',
                    'KSÜ Avşar Kampüsü',
                ],
            },
            {
                'name': 'H26',
                'route_description': 'Kahramanmaraş Otogarı - Tekerek Yolu - Şelale Park - Hasancıklı',
                'stop_names': [
                    'Kahramanmaraş Otogarı',
                    'Tekerek Yolu',
                    'Şelale Park',
                    'Hasancıklı',
                    'Kahramanmaraş Büyükşehir Belediyesi',
                ],
            },
            {
                'name': 'H3',
                'route_description': 'Doğukent - Vali Saim Çotur - EXPO Alanı - NFK Şehir Hastanesi',
                'stop_names': [
                    'Doğukent',
                    'Vali Saim Çotur',
                    'EXPO Alanı',
                    'NFK Şehir Hastanesi',
                    'Ulu Cami',
                ],
            },
            {
                'name': 'H13',
                'route_description': 'Güneşevler - Üngüt - Adliye - Kahramanmaraş Büyükşehir Belediyesi',
                'stop_names': [
                    'Güneşevler',
                    'Üngüt',
                    'Adliye',
                    'Kahramanmaraş Büyükşehir Belediyesi',
                    'Piazza AVM',
                ],
            },
            {
                'name': 'H34',
                'route_description': 'Kuyumcukent - Sanayi - Çocuk Hastanesi - Piazza AVM - KSÜ Avşar Kampüsü',
                'stop_names': [
                    'Kuyumcukent',
                    'Sanayi',
                    'Çocuk Hastanesi',
                    'Piazza AVM',
                    'Binevler',
                    'KSÜ Avşar Kampüsü',
                ],
            },
            {
                'name': '7',
                'route_description': 'Şehir merkezi - Ulu Cami - Otogar - Piazza AVM',
                'stop_names': ['Ulu Cami', 'Piazza AVM', 'Kahramanmaraş Otogarı', 'Binevler'],
            },
            {
                'name': '8',
                'route_description': 'Binevler - Üngüt - Şelale Park - Adliye',
                'stop_names': ['Binevler', 'Üngüt', 'Şelale Park', 'Adliye'],
            },
            {
                'name': '11',
                'route_description': 'Kahramanmaraş Büyükşehir Belediyesi - Piazza AVM - Çocuk Hastanesi',
                'stop_names': ['Kahramanmaraş Büyükşehir Belediyesi', 'Piazza AVM', 'Çocuk Hastanesi'],
            },
            {
                'name': '12',
                'route_description': 'Otogar - Tekerek Yolu - KSÜ Avşar Kampüsü',
                'stop_names': ['Kahramanmaraş Otogarı', 'Tekerek Yolu', 'KSÜ Avşar Kampüsü'],
            },
            {
                'name': '16',
                'route_description': 'Üngüt - Güneşevler - Sanayi - Binevler',
                'stop_names': ['Üngüt', 'Güneşevler', 'Sanayi', 'Binevler'],
            },
            {
                'name': '18',
                'route_description': 'Adliye - Ulu Cami - Şelale Park - Piazza AVM',
                'stop_names': ['Adliye', 'Ulu Cami', 'Şelale Park', 'Piazza AVM'],
            },
            {
                'name': '22',
                'route_description': 'KSÜ Avşar Kampüsü - Çocuk Hastanesi - Binevler',
                'stop_names': ['KSÜ Avşar Kampüsü', 'Çocuk Hastanesi', 'Binevler'],
            },
            {
                'name': '29',
                'route_description': 'Doğukent - EXPO Alanı - NFK Şehir Hastanesi - Ulu Cami',
                'stop_names': ['Doğukent', 'EXPO Alanı', 'NFK Şehir Hastanesi', 'Ulu Cami'],
            },
            {
                'name': '30B',
                'route_description': 'Otogar - Piazza AVM - Adliye - Güneşevler',
                'stop_names': ['Kahramanmaraş Otogarı', 'Piazza AVM', 'Adliye', 'Güneşevler'],
            },
            {
                'name': '32B',
                'route_description': 'Önsen yönü bağlantısı - Otogar - KSÜ Avşar Kampüsü',
                'stop_names': ['Kahramanmaraş Otogarı', 'KSÜ Avşar Kampüsü', 'Binevler'],
            },
            {
                'name': '33',
                'route_description': 'Binevler - Şelale Park - Kahramanmaraş Büyükşehir Belediyesi',
                'stop_names': ['Binevler', 'Şelale Park', 'Kahramanmaraş Büyükşehir Belediyesi'],
            },
            {
                'name': '34B',
                'route_description': 'Sanayi - Çocuk Hastanesi - KSÜ Avşar Kampüsü',
                'stop_names': ['Sanayi', 'Çocuk Hastanesi', 'KSÜ Avşar Kampüsü'],
            },
            {
                'name': '35',
                'route_description': 'Piazza AVM - Ulu Cami - Adliye',
                'stop_names': ['Piazza AVM', 'Ulu Cami', 'Adliye'],
            },
            {
                'name': '36B',
                'route_description': 'Güneşevler - Üngüt - Binevler',
                'stop_names': ['Güneşevler', 'Üngüt', 'Binevler'],
            },
            {
                'name': '37',
                'route_description': 'Şelale Park - Piazza AVM - Ulu Cami',
                'stop_names': ['Şelale Park', 'Piazza AVM', 'Ulu Cami'],
            },
            {
                'name': '37B',
                'route_description': 'Kahramanmaraş Büyükşehir Belediyesi - Adliye - EXPO Alanı',
                'stop_names': ['Kahramanmaraş Büyükşehir Belediyesi', 'Adliye', 'EXPO Alanı'],
            },
            {
                'name': '39B',
                'route_description': 'Hasancıklı - Tekerek Yolu - Otogar',
                'stop_names': ['Hasancıklı', 'Tekerek Yolu', 'Kahramanmaraş Otogarı'],
            },
            {
                'name': '78/B',
                'route_description': 'Önsen - Kurtlar TOKİ - KSÜ Avşar Kampüsü',
                'stop_names': ['KSÜ Avşar Kampüsü', 'Binevler', 'Kahramanmaraş Otogarı'],
            },
        ]

        lines = []
        for spec in line_specs:
            line, _ = BusLine.objects.get_or_create(
                name=spec['name'],
                defaults={'route_description': spec['route_description']},
            )
            if line.route_description != spec['route_description']:
                line.route_description = spec['route_description']
                line.save(update_fields=['route_description'])

            line.stops.set([stop_lookup[name] for name in spec['stop_names']])
            lines.append(line)
        return lines

    def _seed_demo_user(self):
        user, _ = User.objects.get_or_create(username='demo_km')
        if not user.email:
            user.email = 'demo@example.com'
            user.save(update_fields=['email'])
        profile, _ = UserProfile.objects.get_or_create(user=user)
        profile.points = 0
        profile.save(update_fields=['points'])
        return user

    def _seed_reports(self, lines, stops, user):
        report_specs = [
            ('H24', 'Piazza AVM', 'GREEN'),
            ('H24', 'KSÜ Avşar Kampüsü', 'YELLOW'),
            ('H26', 'Şelale Park', 'RED'),
            ('H34', 'Çocuk Hastanesi', 'RED'),
            ('H3', 'NFK Şehir Hastanesi', 'BLACK'),
            ('H13', 'Kahramanmaraş Büyükşehir Belediyesi', 'YELLOW'),
        ]

        line_lookup = {line.name: line for line in lines}
        stop_lookup = {stop.name: stop for stop in stops}
        points_map = {
            'GREEN': 5,
            'YELLOW': 10,
            'RED': 15,
            'BLACK': 20,
        }

        total_points = 0
        created_reports = 0
        for line_name, stop_name, density_level in report_specs:
            _, created = DensityReport.objects.get_or_create(
                bus_line=line_lookup[line_name],
                bus_stop=stop_lookup[stop_name],
                user=user,
                density_level=density_level,
            )
            created_reports += int(created)
            if created:
                total_points += points_map.get(density_level, 0)

        profile = UserProfile.objects.get(user=user)
        if total_points:
            profile.points += total_points
            profile.save(update_fields=['points'])

        return created_reports
