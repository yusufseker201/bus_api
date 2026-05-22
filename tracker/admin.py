import csv
from xml.sax.saxutils import escape

from django.contrib import admin
from django.http import HttpResponse, JsonResponse
from django.template.response import TemplateResponse
from django.urls import path
from django.utils import formats, timezone

from .live_reports import build_live_report_snapshot
from .models import BusLine, BusStop, DensityReport, UserProfile


class ExportReportMixin:
    export_fields = (
        ('ID', 'id'),
        ('Otobus Hatti', 'bus_line_name'),
        ('Durak', 'bus_stop_name'),
        ('Ilce', 'bus_stop_district'),
        ('Yogunluk Kodu', 'density_level'),
        ('Yogunluk Durumu', 'density_level_display'),
        ('Kullanici', 'username'),
        ('Ad Soyad', 'full_name'),
        ('Aktif Mi', 'is_active_display'),
        ('Rapor Tarihi', 'reported_at_display'),
    )

    def _report_row(self, obj):
        full_name = obj.user.get_full_name().strip() if obj.user else ''
        return {
            'id': obj.id,
            'bus_line_name': obj.bus_line.name,
            'bus_stop_name': obj.bus_stop.name if obj.bus_stop else '-',
            'bus_stop_district': obj.bus_stop.district if obj.bus_stop else '',
            'density_level': obj.density_level,
            'density_level_display': obj.get_density_level_display(),
            'username': obj.user.username if obj.user else '-',
            'full_name': full_name or '-',
            'is_active_display': 'Evet' if obj.is_active else 'Hayir',
            'reported_at_display': formats.date_format(
                timezone.localtime(obj.reported_at),
                'd.m.Y H:i:s',
                use_l10n=True,
            ),
        }

    @admin.action(description='Secilen raporlari CSV olarak disa aktar')
    def export_as_csv(self, request, queryset):
        response = HttpResponse(content_type='text/csv; charset=utf-8-sig')
        response['Content-Disposition'] = 'attachment; filename="yogunluk_raporlari.csv"'
        response.write('\ufeff')

        writer = csv.writer(response)
        writer.writerow([header for header, _ in self.export_fields])

        for report in queryset.select_related('bus_line', 'bus_stop', 'user'):
            row = self._report_row(report)
            writer.writerow([row[key] for _, key in self.export_fields])

        return response

    @admin.action(description='Secilen raporlari Excel olarak disa aktar')
    def export_as_excel(self, request, queryset):
        response = HttpResponse(
            content_type='application/vnd.ms-excel; charset=utf-8-sig',
        )
        response['Content-Disposition'] = 'attachment; filename="yogunluk_raporlari.xls"'
        response.write('\ufeff')

        headers_xml = ''.join(
            f'<Cell><Data ss:Type="String">{escape(header)}</Data></Cell>'
            for header, _ in self.export_fields
        )
        rows_xml = []

        for report in queryset.select_related('bus_line', 'bus_stop', 'user'):
            row = self._report_row(report)
            cell_xml = ''.join(
                f'<Cell><Data ss:Type="String">{escape(str(row[key]))}</Data></Cell>'
                for _, key in self.export_fields
            )
            rows_xml.append(f'<Row>{cell_xml}</Row>')

        workbook = f'''<?xml version="1.0" encoding="UTF-8"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
 <Worksheet ss:Name="Yogunluk Raporlari">
  <Table>
   <Row>{headers_xml}</Row>
   {''.join(rows_xml)}
  </Table>
 </Worksheet>
</Workbook>'''

        response.write(workbook)
        return response


def live_reports_page(request):
    snapshot = build_live_report_snapshot(limit=20)
    context = {
        **admin.site.each_context(request),
        'title': 'Canli Bildirimler',
        'subtitle': 'Son 1 saatte gelen veya aktif kalan otobus yogunluk raporlari',
        'live_reports': snapshot['reports'],
        'live_report_count': snapshot['count'],
        'updated_at': snapshot['updated_at'],
    }
    return TemplateResponse(request, 'admin/tracker/live_reports.html', context)


def live_reports_data(request):
    return JsonResponse(build_live_report_snapshot(limit=20))


_default_admin_get_urls = admin.site.get_urls


def _custom_admin_urls():
    custom_urls = [
        path(
            'live-reports/',
            admin.site.admin_view(live_reports_page),
            name='live_reports_dashboard',
        ),
        path(
            'live-reports/data/',
            admin.site.admin_view(live_reports_data),
            name='live_reports_data',
        ),
    ]
    return custom_urls + _default_admin_get_urls()


admin.site.get_urls = _custom_admin_urls
admin.site.index_template = 'admin/tracker/index.html'
admin.site.site_header = 'Kahramanmaras Otobus Yogunluk Yonetimi'
admin.site.site_title = 'Canli Bildirim Merkezi'
admin.site.index_title = 'Operasyon Paneli'


@admin.register(BusLine)
class BusLineAdmin(admin.ModelAdmin):
    list_display = ('name', 'route_description', 'stop_count', 'report_count')
    search_fields = ('name', 'route_description', 'stops__name')
    filter_horizontal = ('stops',)
    ordering = ('name',)

    @admin.display(description='Durak Sayisi')
    def stop_count(self, obj):
        return obj.stops.count()

    @admin.display(description='Rapor Sayisi')
    def report_count(self, obj):
        return obj.reports.count()


@admin.register(BusStop)
class BusStopAdmin(admin.ModelAdmin):
    list_display = (
        'name',
        'district',
        'is_major_hub',
        'latitude',
        'longitude',
        'line_count',
        'report_count',
    )
    search_fields = ('name', 'district', 'bus_lines__name')
    list_filter = ('district', 'is_major_hub')
    ordering = ('name',)

    @admin.display(description='Hat Sayisi')
    def line_count(self, obj):
        return obj.bus_lines.count()

    @admin.display(description='Rapor Sayisi')
    def report_count(self, obj):
        return obj.reports.count()


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = (
        'user',
        'full_name',
        'points',
        'trust_score',
        'is_shadowbanned',
    )
    search_fields = ('user__username', 'user__first_name', 'user__last_name', 'user__email')
    list_filter = ('is_shadowbanned',)
    ordering = ('-points', 'user__username')

    @admin.display(description='Ad Soyad')
    def full_name(self, obj):
        full_name = obj.user.get_full_name().strip()
        return full_name or '-'


@admin.register(DensityReport)
class DensityReportAdmin(ExportReportMixin, admin.ModelAdmin):
    list_display = (
        'id',
        'bus_line',
        'bus_stop',
        'density_level',
        'density_badge',
        'user',
        'reported_at',
        'is_active',
    )
    list_filter = (
        'density_level',
        'is_active',
        'bus_line',
        ('reported_at', admin.DateFieldListFilter),
    )
    search_fields = (
        'bus_line__name',
        'bus_stop__name',
        'bus_stop__district',
        'user__username',
        'user__first_name',
        'user__last_name',
        'user__email',
    )
    date_hierarchy = 'reported_at'
    list_select_related = ('bus_line', 'bus_stop', 'user')
    ordering = ('-reported_at',)
    actions = ('export_as_csv', 'export_as_excel')
    autocomplete_fields = ('bus_line', 'bus_stop', 'user')

    @admin.display(description='Yogunluk Durumu')
    def density_badge(self, obj):
        return obj.get_density_level_display()
