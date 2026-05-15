import 'density_level.dart';

class BusStop {
  const BusStop({
    required this.id,
    required this.name,
    required this.area,
    required this.distanceKm,
    required this.currentDensity,
    required this.latitude,
    required this.longitude,
    this.busLines = const [],
  });

  final String id;
  final String name;
  final String area;
  final double distanceKm;
  final DensityLevel currentDensity;
  final double latitude;
  final double longitude;
  final List<String> busLines;

  BusStop copyWith({
    String? id,
    String? name,
    String? area,
    double? distanceKm,
    DensityLevel? currentDensity,
    double? latitude,
    double? longitude,
    List<String>? busLines,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      distanceKm: distanceKm ?? this.distanceKm,
      currentDensity: currentDensity ?? this.currentDensity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      busLines: busLines ?? this.busLines,
    );
  }
}
