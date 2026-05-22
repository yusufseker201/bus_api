import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import '../models/density_report.dart';
import '../models/user_profile.dart';

class ApiService {
  ApiService({
    http.Client? client,
    String? apiBaseUrl,
    String? Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        apiBaseUrl = apiBaseUrl ??
            (kIsWeb
                ? '/api'
                : const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://10.0.2.2:8000/api',
                  )),
        _tokenProvider = tokenProvider;

  final http.Client _client;
  final String apiBaseUrl;
  final Random _random = Random(42);
  final String? Function()? _tokenProvider;

  Map<String, String> _authHeaders({bool json = false}) {
    final token = _tokenProvider?.call();
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  Future<List<Bus>> fetchBuses() async {
    final lines = await _getJsonList('$apiBaseUrl/bus-lines/');
    final reports = await _getJsonList('$apiBaseUrl/reports/');
    final reportsByLine = _groupReportsByLine(reports);

    return lines.map((line) {
      final lineId = (line['id'] as num?)?.toInt() ??
          int.tryParse(line['id'].toString()) ??
          0;
      final lineReports = reportsByLine[lineId] ?? const [];
      final latest = lineReports.isNotEmpty ? lineReports.first : null;
      final density = _densityFromApiValue(latest?['density_level'] as String?);
      final stops = (line['stops'] as List<dynamic>? ?? const [])
          .map((stop) => stop as Map<String, dynamic>)
          .toList();
      final currentStopName = (latest?['bus_stop_name'] as String?) ??
          (stops.isNotEmpty
              ? (stops.first['name'] as String? ?? 'Bilinmeyen durak')
              : 'Bilinmeyen durak');
      final nextStopName = stops.length > 1
          ? (stops[1]['name'] as String? ?? currentStopName)
          : currentStopName;

      return Bus(
        id: line['id'].toString(),
        routeNumber: (line['name'] as String?) ?? line['id'].toString(),
        routeName: (line['name'] as String?) ?? line['id'].toString(),
        origin: stops.isNotEmpty
            ? (stops.first['name'] as String? ?? 'Kahramanmaraş')
            : 'Kahramanmaraş',
        destination: stops.isNotEmpty
            ? (stops.last['name'] as String? ?? 'Kahramanmaraş')
            : 'Kahramanmaraş',
        currentStopName: currentStopName,
        nextStopName: nextStopName,
        occupancyPercent: _estimateOccupancy(density, lineReports.length),
        densityLevel: density,
        etaMinutes: 2 + _random.nextInt(10),
        lastUpdated: latest != null
            ? DateTime.tryParse(latest['reported_at'] as String? ?? '') ??
                DateTime.now()
            : DateTime.now(),
        popularityScore:
            (line['reports_count'] as num?)?.toInt() ?? lineReports.length,
      );
    }).toList();
  }

  Future<List<BusStop>> fetchBusStops() async {
    final stops = await _getJsonList('$apiBaseUrl/bus-stops/');
    final reports = await _getJsonList('$apiBaseUrl/reports/');
    final reportsByStop = _groupReportsByStop(reports);

    return stops.map((stop) {
      final stopId = (stop['id'] as num?)?.toInt() ??
          int.tryParse(stop['id'].toString()) ??
          0;
      final stopReports = reportsByStop[stopId] ?? const [];
      final latest = stopReports.isNotEmpty ? stopReports.first : null;
      return BusStop(
        id: stop['id'].toString(),
        name: (stop['name'] as String?) ?? stop['id'].toString(),
        area: '',
        distanceKm: 0,
        currentDensity:
            _densityFromApiValue(latest?['density_level'] as String?),
        latitude: _toDouble(stop['latitude']),
        longitude: _toDouble(stop['longitude']),
        busLines: (stop['bus_lines'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
      );
    }).toList();
  }

  Future<UserProfile> getUserProfile() async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/profiles/me/'),
      headers: _authHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Profil alınamadı (${response.statusCode}).');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final reports = (json['recent_reports'] as List<dynamic>? ?? const [])
        .map((item) => _reportFromJson(item as Map<String, dynamic>))
        .toList();
    final points = (json['points'] as num?)?.toInt() ?? 0;
    return UserProfile(
      userName: (json['username'] as String?) ?? 'Kullanıcı',
      totalPoints: points,
      currentRank: _rankForPoints(points),
      badgeName: reports.isNotEmpty ? 'Aktif Raporcu' : 'Yeni Başlayan',
      recentReports: reports,
    );
  }

  Future<List<DensityReport>> fetchDensityReports({int limit = 20}) async {
    final reports = await _getJsonList('$apiBaseUrl/reports/');
    final items = reports
        .map((item) => _reportFromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (items.length <= limit) {
      return items;
    }
    return items.take(limit).toList();
  }

  Future<DensityReport> submitReport({
    required String busId,
    required String routeNumber,
    required String stopName,
    required DensityLevel densityLevel,
    required bool locationValidated,
    double? userLat,
    double? userLon,
  }) async {
    final busLines = await _getJsonList('$apiBaseUrl/bus-lines/');
    final line = busLines.firstWhere(
      (item) => item['name'].toString() == routeNumber,
      orElse: () => busLines.isNotEmpty
          ? busLines.first
          : <String, dynamic>{'id': busId, 'name': routeNumber},
    );

    final stops = (line['stops'] as List<dynamic>? ?? const [])
        .map((item) => item as Map<String, dynamic>)
        .toList();
    final stop = stops.firstWhere(
      (item) => item['name'].toString() == stopName,
      orElse: () => stops.isNotEmpty
          ? stops.first
          : <String, dynamic>{'id': null, 'name': stopName},
    );

    final fallbackLat = _toDouble(stop['latitude']);
    final fallbackLon = _toDouble(stop['longitude']);

    final payload = <String, dynamic>{
      'bus_line': line['id'],
      'bus_stop': stop['id'],
      'density_level': _apiValueForDensity(densityLevel),
      'user_lat': userLat ?? fallbackLat,
      'user_lon': userLon ?? fallbackLon,
    };

    final response = await _client.post(
      Uri.parse('$apiBaseUrl/reports/submit/'),
      headers: _authHeaders(json: true),
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      final detail = body is Map<String, dynamic>
          ? (body['detail']?.toString() ?? body.toString())
          : body?.toString();
      throw StateError(
          detail ?? 'Rapor gönderilemedi (${response.statusCode}).');
    }
    return _reportFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Bus?> fetchBusById(String busId) async {
    final buses = await fetchBuses();
    return buses.where((bus) => bus.id == busId).cast<Bus?>().firstOrNull;
  }

  Future<List<dynamic>> _getJsonList(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: _authHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Request failed: $url');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    throw StateError('Expected a JSON list from $url');
  }

  Map<int, List<Map<String, dynamic>>> _groupReportsByLine(
      List<dynamic> reports) {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final item in reports) {
      final report = item as Map<String, dynamic>;
      final busLineId = (report['bus_line'] as num?)?.toInt();
      if (busLineId == null) continue;
      grouped.putIfAbsent(busLineId, () => []).add(report);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final aTime = DateTime.tryParse(a['reported_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['reported_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    }
    return grouped;
  }

  Map<int, List<Map<String, dynamic>>> _groupReportsByStop(
      List<dynamic> reports) {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final item in reports) {
      final report = item as Map<String, dynamic>;
      final busStopId = (report['bus_stop'] as num?)?.toInt();
      if (busStopId == null) continue;
      grouped.putIfAbsent(busStopId, () => []).add(report);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final aTime = DateTime.tryParse(a['reported_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['reported_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    }
    return grouped;
  }

  DensityLevel _densityFromApiValue(String? value) {
    return switch (value) {
      'GREEN' => DensityLevel.empty,
      'YELLOW' => DensityLevel.moderate,
      'RED' => DensityLevel.crowded,
      'BLACK' => DensityLevel.full,
      _ => DensityLevel.moderate,
    };
  }

  String _apiValueForDensity(DensityLevel level) {
    return switch (level) {
      DensityLevel.empty => 'GREEN',
      DensityLevel.moderate => 'YELLOW',
      DensityLevel.crowded => 'RED',
      DensityLevel.full => 'BLACK',
    };
  }

  DensityReport _reportFromJson(Map<String, dynamic> json) {
    final density = _densityFromApiValue(json['density_level'] as String?);
    return DensityReport(
      id: json['id'].toString(),
      busId: (json['bus_line'] ?? '').toString(),
      busRouteNumber: (json['bus_line_name'] as String?) ?? '',
      stopName: (json['bus_stop_name'] as String?) ?? '',
      densityLevel: density,
      createdAt: DateTime.tryParse(json['reported_at'] as String? ?? '') ??
          DateTime.now(),
      pointsAwarded: density.reportPoints,
      locationValidated: (json['is_active'] as bool?) ?? true,
      busLine: (json['bus_line_name'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
      reporterName: (json['user_username'] as String?) ?? 'Topluluk',
    );
  }

  int _estimateOccupancy(DensityLevel density, int reportCount) {
    final base = switch (density) {
      DensityLevel.empty => 15,
      DensityLevel.moderate => 45,
      DensityLevel.crowded => 78,
      DensityLevel.full => 100,
    };
    return (base + min(reportCount * 2, 10)).clamp(0, 100).toInt();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _rankForPoints(int points) {
    if (points >= 2000) return 'Ulaşım Efsanesi';
    if (points >= 1400) return 'Hat Rehberi';
    if (points >= 800) return 'Şehir Gözlemcisi';
    if (points >= 300) return 'Durak Kaşifi';
    return 'Yeni Katılımcı';
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
