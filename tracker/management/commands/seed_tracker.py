from django.core.management.base import BaseCommand

from tracker.models import BusLine, DensityReport


class Command(BaseCommand):
    help = 'Seed the tracker app with demo bus lines and crowd reports.'

    def handle(self, *args, **options):
        bus_lines = [
            ('34A', 'Central Station to University Gate'),
            ('12B', 'Market Square to Central Station'),
            ('7C', 'Campus Shuttle via City Hospital'),
        ]

        lines = []
        for name, description in bus_lines:
            line, created = BusLine.objects.get_or_create(
                name=name,
                defaults={'route_description': description},
            )
            if not created and line.route_description != description:
                line.route_description = description
                line.save(update_fields=['route_description'])
            lines.append(line)

        report_specs = [
            (lines[0], 'GREEN'),
            (lines[0], 'RED'),
            (lines[1], 'YELLOW'),
            (lines[2], 'BLACK'),
        ]

        created_reports = 0
        for bus_line, density_level in report_specs:
            _, created = DensityReport.objects.get_or_create(
                bus_line=bus_line,
                density_level=density_level,
                user=None,
            )
            created_reports += int(created)

        self.stdout.write(self.style.SUCCESS(
            f'Seeded {len(lines)} bus lines and {created_reports} demo reports.'
        ))
