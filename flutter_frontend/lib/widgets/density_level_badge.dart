import 'package:flutter/material.dart';

import '../models/density_level.dart';

class DensityLevelBadge extends StatelessWidget {
  const DensityLevelBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  final DensityLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 8 : 10,
            height: compact ? 8 : 10,
            decoration: BoxDecoration(
              color: palette.foreground,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            compact ? level.label : '${level.label} yoğunluk',
            style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11.5 : 12.5,
            ),
          ),
        ],
      ),
    );
  }

  _DensityBadgePalette _paletteFor(DensityLevel level) {
    return switch (level) {
      DensityLevel.empty => const _DensityBadgePalette(
          background: Color(0xFFE1F7EA),
          foreground: Color(0xFF1F7A45),
        ),
      DensityLevel.moderate => const _DensityBadgePalette(
          background: Color(0xFFFFF1D7),
          foreground: Color(0xFFB06A0A),
        ),
      DensityLevel.crowded => const _DensityBadgePalette(
          background: Color(0xFFFBE0D9),
          foreground: Color(0xFFC45A35),
        ),
      DensityLevel.full => const _DensityBadgePalette(
          background: Color(0xFFE4E8EA),
          foreground: Color(0xFF34424C),
        ),
    };
  }
}

class _DensityBadgePalette {
  const _DensityBadgePalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
