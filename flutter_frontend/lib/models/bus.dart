import 'density_level.dart';

class Bus {
  const Bus({
    required this.id,
    required this.routeNumber,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.currentStopName,
    required this.nextStopName,
    required this.occupancyPercent,
    required this.densityLevel,
    required this.etaMinutes,
    required this.lastUpdated,
    required this.popularityScore,
  });

  final String id;
  final String routeNumber;
  final String routeName;
  final String origin;
  final String destination;
  final String currentStopName;
  final String nextStopName;
  final int occupancyPercent;
  final DensityLevel densityLevel;
  final int etaMinutes;
  final DateTime lastUpdated;
  final int popularityScore;

  String get displayName => 'Hat $routeNumber';

  String get routeTitle => '$origin → $destination';

  String get predictionText {
    final percent = switch (densityLevel) {
      DensityLevel.empty => 'Genellikle %20 dolu',
      DensityLevel.moderate => 'Genellikle %45 dolu',
      DensityLevel.crowded => 'Genellikle %80 dolu',
      DensityLevel.full => 'Genellikle %90+ dolu',
    };
    return '$percent bu saatlerde';
  }

  Bus copyWith({
    String? id,
    String? routeNumber,
    String? routeName,
    String? origin,
    String? destination,
    String? currentStopName,
    String? nextStopName,
    int? occupancyPercent,
    DensityLevel? densityLevel,
    int? etaMinutes,
    DateTime? lastUpdated,
    int? popularityScore,
  }) {
    return Bus(
      id: id ?? this.id,
      routeNumber: routeNumber ?? this.routeNumber,
      routeName: routeName ?? this.routeName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      currentStopName: currentStopName ?? this.currentStopName,
      nextStopName: nextStopName ?? this.nextStopName,
      occupancyPercent: occupancyPercent ?? this.occupancyPercent,
      densityLevel: densityLevel ?? this.densityLevel,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      popularityScore: popularityScore ?? this.popularityScore,
    );
  }
}
