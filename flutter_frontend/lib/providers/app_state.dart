import 'package:flutter/foundation.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import '../models/density_report.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'session_state.dart';

class AppState extends ChangeNotifier {
  AppState(this._apiService, this._session);

  ApiService _apiService;
  SessionState _session;

  bool isLoading = true;
  String? errorMessage;
  List<Bus> buses = const [];
  List<BusStop> stops = const [];
  List<DensityReport> liveReports = const [];
  UserProfile? profile;

  Bus? selectedBus;
  BusStop? selectedStop;

  void updateDependencies(ApiService apiService, SessionState session) {
    _apiService = apiService;
    _session = session;
  }

  Future<void> loadInitialData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.fetchBuses(),
        _apiService.fetchBusStops(),
        _apiService.fetchDensityReports(),
      ]);
      buses = results[0] as List<Bus>;
      stops = results[1] as List<BusStop>;
      liveReports = results[2] as List<DensityReport>;

      if (_session.isLoggedIn) {
        profile = await _apiService.getUserProfile();
      } else {
        profile = null;
      }
    } catch (e) {
      errorMessage = e.toString();
    }
    final previousStopName = selectedStop?.name;
    selectedBus = buses.isNotEmpty ? buses.first : null;
    selectedStop = stops.isNotEmpty
        ? stops.firstWhere(
            (stop) => stop.name == previousStopName,
            orElse: () => stops.first,
          )
        : null;
    isLoading = false;
    notifyListeners();
  }

  void selectBus(Bus bus) {
    selectedBus = bus;
    notifyListeners();
  }

  void selectStop(BusStop stop) {
    selectedStop = stop;
    notifyListeners();
  }

  BusStop nearestStopForBus(Bus bus) {
    return stops.firstWhere(
      (stop) => stop.name == bus.currentStopName,
      orElse: () => stops.isNotEmpty
          ? stops.first
          : const BusStop(
              id: 'fallback',
              name: 'Unknown Stop',
              area: 'Unknown',
              distanceKm: 0,
              currentDensity: DensityLevel.moderate,
              latitude: 0,
              longitude: 0,
            ),
    );
  }

  Future<DensityReport> submitReport({
    required Bus bus,
    required BusStop stop,
    required DensityLevel densityLevel,
    double? userLat,
    double? userLon,
  }) async {
    final report = await _apiService.submitReport(
      busId: bus.id,
      routeNumber: bus.routeNumber,
      stopName: stop.name,
      densityLevel: densityLevel,
      locationValidated: true,
      userLat: userLat ?? stop.latitude,
      userLon: userLon ?? stop.longitude,
    );

    await loadInitialData();
    return report;
  }

  List<Bus> busesForSelectedStop() {
    final stop = selectedStop;
    if (stop == null || stop.busLines.isEmpty) {
      return buses;
    }

    return buses
        .where((bus) => stop.busLines.contains(bus.routeNumber))
        .toList();
  }

  int get activeLiveReportCount =>
      liveReports.where((report) => report.isActive).length;
}
