import 'package:flutter/material.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import 'density_level_badge.dart';

class BusDensityCard extends StatelessWidget {
  const BusDensityCard({
    super.key,
    required this.bus,
    required this.stop,
    required this.onTap,
    required this.onReport,
  });

  final Bus bus;
  final BusStop stop;
  final VoidCallback onTap;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = bus.densityLevel.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.directions_bus_filled_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bus.routeTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Durak: ${stop.name}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  DensityLevelBadge(level: bus.densityLevel, compact: true),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Güncel durak',
                      value: bus.currentStopName,
                      icon: Icons.place_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Varış',
                      value: '${bus.etaMinutes} dk',
                      icon: Icons.schedule_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: bus.occupancyPercent / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: accent,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '%${bus.occupancyPercent} doluluk',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${_timeAgo(bus.lastUpdated)} güncellendi',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('Detay'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.how_to_vote_outlined),
                    label: const Text('Raporla'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final minutes = DateTime.now().difference(dateTime).inMinutes;
    if (minutes < 1) return 'az önce';
    if (minutes == 1) return '1 dk önce';
    return '$minutes dk önce';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
