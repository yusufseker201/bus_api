import 'package:flutter/material.dart';

enum DensityLevel {
  empty,
  moderate,
  crowded,
  full,
}

extension DensityLevelX on DensityLevel {
  String get label => switch (this) {
        DensityLevel.empty => 'Boş',
        DensityLevel.moderate => 'Orta',
        DensityLevel.crowded => 'Kalabalık',
        DensityLevel.full => 'Tam dolu',
      };

  String get shortLabel => switch (this) {
        DensityLevel.empty => 'Yeşil',
        DensityLevel.moderate => 'Sarı',
        DensityLevel.crowded => 'Kırmızı',
        DensityLevel.full => 'Siyah',
      };

  Color get color => switch (this) {
        DensityLevel.empty => const Color(0xFF2E7D32),
        DensityLevel.moderate => const Color(0xFFF9A825),
        DensityLevel.crowded => const Color(0xFFC62828),
        DensityLevel.full => const Color(0xFF111111),
      };

  Color get contentColor => switch (this) {
        DensityLevel.full => Colors.white,
        _ => Colors.white,
      };

  int get reportPoints => switch (this) {
        DensityLevel.empty => 5,
        DensityLevel.moderate => 10,
        DensityLevel.crowded => 15,
        DensityLevel.full => 20,
      };

  double get occupancyHint => switch (this) {
        DensityLevel.empty => 0.1,
        DensityLevel.moderate => 0.45,
        DensityLevel.crowded => 0.8,
        DensityLevel.full => 1.0,
      };
}
