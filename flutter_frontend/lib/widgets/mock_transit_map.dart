import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import '../theme/app_theme.dart';

class MockTransitMap extends StatelessWidget {
  const MockTransitMap({
    super.key,
    required this.buses,
    required this.stops,
    required this.onBusTap,
    required this.onStopTap,
    required this.selectedStopId,
  });

  final List<Bus> buses;
  final List<BusStop> stops;
  final ValueChanged<Bus> onBusTap;
  final ValueChanged<BusStop> onStopTap;
  final String? selectedStopId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleStops = stops.take(8).toList();
    final visibleBuses = buses.take(5).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight && constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 360.0;

        return SizedBox(
          height: height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              boxShadow: AppTheme.softShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Durak yoğunluğu',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Harita görünümü, seçili durak ve anlık otobüs noktaları',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _MiniLegend(levels: DensityLevel.values),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFD6EEF9),
                          Color(0xFFF8FBFE),
                          Color(0xFFEAF5FF),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Positioned.fill(child: _MapBackdrop()),
                        ..._buildStopPins(visibleStops),
                        ..._buildBusPins(visibleBuses),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStopPins(List<BusStop> visibleStops) {
    const anchorPoints = <Alignment>[
      Alignment(-0.78, -0.46),
      Alignment(-0.44, 0.08),
      Alignment(-0.14, 0.34),
      Alignment(0.1, 0.18),
      Alignment(0.42, -0.04),
      Alignment(0.72, -0.42),
      Alignment(0.58, 0.28),
      Alignment(-0.02, -0.58),
    ];

    return visibleStops.asMap().entries.map((entry) {
      final stop = entry.value;
      final alignment = anchorPoints[entry.key % anchorPoints.length];
      final selected = stop.id == selectedStopId;

      return Align(
        alignment: alignment,
        child: GestureDetector(
          onTap: () => onStopTap(stop),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: selected ? 0.98 : 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? stop.currentDensity.color : Colors.white,
                width: selected ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x160E5A53)
                      .withValues(alpha: selected ? 0.18 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus_filled_rounded,
                    size: 16, color: stop.currentDensity.color),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    stop.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildBusPins(List<Bus> visibleBuses) {
    const anchorPoints = <Alignment>[
      Alignment(-0.36, -0.18),
      Alignment(0.28, -0.02),
      Alignment(-0.02, 0.42),
      Alignment(0.66, -0.12),
      Alignment(-0.56, 0.32),
    ];

    return visibleBuses.asMap().entries.map((entry) {
      final bus = entry.value;
      final alignment = anchorPoints[entry.key % anchorPoints.length];

      return Align(
        alignment: alignment,
        child: GestureDetector(
          onTap: () => onBusTap(bus),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: bus.densityLevel.color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: bus.densityLevel.color.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus_filled_rounded,
                    color: bus.densityLevel.contentColor, size: 15),
                const SizedBox(width: 6),
                Text(
                  bus.routeNumber,
                  style: TextStyle(
                    color: bus.densityLevel.contentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _MiniLegend extends StatelessWidget {
  const _MiniLegend({required this.levels});

  final List<DensityLevel> levels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels
          .map(
            (level) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: level.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    level.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapGridPainter(),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF4F8FA3).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = const Color(0xFFA7C7D3).withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final primaryPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.32, size.height * 0.38,
          size.width * 0.56, size.height * 0.32)
      ..quadraticBezierTo(size.width * 0.74, size.height * 0.28,
          size.width * 0.95, size.height * 0.18);

    final secondaryPath = Path()
      ..moveTo(size.width * 0.45, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.24,
          size.width * 0.5, size.height * 0.48)
      ..quadraticBezierTo(size.width * 0.47, size.height * 0.78,
          size.width * 0.36, size.height * 1.02);

    final tertiaryPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.46, size.height * 0.0,
          size.width * 0.8, size.height * 0.04);

    canvas.drawPath(primaryPath, linePaint);
    canvas.drawPath(secondaryPath, linePaint);
    canvas.drawPath(tertiaryPath, accentPaint);

    for (var i = 0; i < 18; i++) {
      final dx = (size.width / 17) * i;
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx + math.sin(i.toDouble()) * 10, size.height),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
