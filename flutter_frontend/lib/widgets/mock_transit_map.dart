import 'package:flutter/material.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import 'density_level_badge.dart';

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

    return AspectRatio(
      aspectRatio: 1.55,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
                  theme.colorScheme.surface,
                ],
              ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePainter(theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Canlı harita',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      const DensityLevelBadge(level: DensityLevel.crowded, compact: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Stack(
                      children: [
                        ..._stopMarkers(context),
                        ..._busMarkers(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _stopMarkers(BuildContext context) {
    final alignments = <Alignment>[
      const Alignment(-0.8, -0.55),
      const Alignment(0.2, -0.2),
      const Alignment(-0.55, 0.35),
      const Alignment(0.75, 0.65),
    ];

    return stops.asMap().entries.map((entry) {
      final stop = entry.value;
      final density = stop.currentDensity;
      final alignment = alignments[entry.key % alignments.length];

      return Align(
        alignment: alignment,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onStopTap(stop),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: stop.id == selectedStopId
                  ? density.color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: stop.id == selectedStopId
                    ? density.color
                    : density.color.withValues(alpha: 0.35),
                width: stop.id == selectedStopId ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: density.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stop.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${stop.distanceKm.toStringAsFixed(1)} km • ${density.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _busMarkers(BuildContext context) {
    final alignments = <Alignment>[
      const Alignment(-0.15, -0.35),
      const Alignment(0.45, 0.05),
      const Alignment(-0.3, 0.6),
    ];

    return buses.asMap().entries.map((entry) {
      final bus = entry.value;
      final alignment = alignments[entry.key % alignments.length];

      return Align(
        alignment: alignment,
        child: GestureDetector(
          onTap: () => onBusTap(bus),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bus.densityLevel.color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: bus.densityLevel.color.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus_filled, color: bus.densityLevel.contentColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  bus.routeNumber,
                  style: TextStyle(
                    color: bus.densityLevel.contentColor,
                    fontWeight: FontWeight.w800,
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

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.1, size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.55, size.width * 0.9, size.height * 0.42)
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.65, size.width * 0.58, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.96, size.width * 0.92, size.height * 0.72);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
