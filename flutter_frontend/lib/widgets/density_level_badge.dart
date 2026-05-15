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
    final color = level.color;
    final text = compact ? level.shortLabel : level.label;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 8,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}
