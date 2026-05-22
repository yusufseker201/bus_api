import 'density_level.dart';

class DensityReport {
  const DensityReport({
    required this.id,
    required this.busId,
    required this.busRouteNumber,
    required this.stopName,
    required this.densityLevel,
    required this.createdAt,
    required this.pointsAwarded,
    required this.locationValidated,
    this.busLine = '',
    this.isActive = true,
    this.reporterName = '',
  });

  final String id;
  final String busId;
  final String busRouteNumber;
  final String stopName;
  final DensityLevel densityLevel;
  final DateTime createdAt;
  final int pointsAwarded;
  final bool locationValidated;
  final String busLine;
  final bool isActive;
  final String reporterName;

  String get displayLine =>
      busRouteNumber.isNotEmpty ? busRouteNumber : busLine;
}
