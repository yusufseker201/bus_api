import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bus.dart';
import '../models/density_level.dart';
import '../providers/app_state.dart';
import '../widgets/density_level_badge.dart';

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({super.key, required this.bus});

  static const routeName = '/route-details';

  final Bus bus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final stop = state.nearestStopForBus(bus);
    final recentReports = state.profile?.recentReports
            .where((report) => report.busId == bus.id)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Hat ${bus.routeNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bus.routeName,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bus.routeTitle,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      DensityLevelBadge(level: bus.densityLevel),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          title: 'Güncel durak',
                          value: bus.currentStopName,
                          icon: Icons.place_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          title: 'Sonraki durak',
                          value: bus.nextStopName,
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          title: 'Yakın durak',
                          value: stop.name,
                          icon: Icons.near_me_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          title: 'Varış',
                          value: '${bus.etaMinutes} dk',
                          icon: Icons.schedule_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yapay zekâ tahmini',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bus.predictionText,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tahmin güveni',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _ConfidenceBar(label: 'Sabah', value: 0.88, color: DensityLevel.full.color),
                  const SizedBox(height: 10),
                  _ConfidenceBar(label: 'Öğle', value: 0.55, color: DensityLevel.moderate.color),
                  const SizedBox(height: 10),
                  _ConfidenceBar(label: 'Akşam', value: 0.73, color: DensityLevel.crowded.color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu hatta son raporlar',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  if (recentReports.isEmpty)
                    Text(
                      'Henüz rapor yok. Django API canlı veri döndürdükçe bu hatta ait vatandaş raporları burada görünecek.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    )
                  else
                    ...recentReports.map(
                      (report) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: report.densityLevel.color.withValues(alpha: 0.14),
                          child: Icon(Icons.markunread, color: report.densityLevel.color),
                        ),
                        title: Text('${report.stopName} • ${report.densityLevel.label}'),
                        subtitle: Text(
                          '${report.pointsAwarded} puan • ${_formatDate(report.createdAt)}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: value,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 44, child: Text('${(value * 100).round()}%')),
      ],
    );
  }
}
