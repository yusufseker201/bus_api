import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../providers/app_state.dart';
import '../widgets/bus_density_card.dart';
import '../widgets/mock_transit_map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onBusSelected,
    required this.onReportRequested,
  });

  final ValueChanged<Bus> onBusSelected;
  final ValueChanged<Bus> onReportRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final selectedStop = state.selectedStop ??
            (state.stops.isNotEmpty ? state.stops.first : null);
        final busesAtStop = state.busesForSelectedStop();

        return RefreshIndicator(
          onRefresh: state.loadInitialData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final mainContent = _MainContent(
                theme: theme,
                selectedStop: selectedStop,
                busesAtStop: busesAtStop.isEmpty ? state.buses : busesAtStop,
                allStops: state.stops,
                selectedStopId: selectedStop?.id,
                onStopTap: state.selectStop,
                onBusTap: onBusSelected,
                onReportRequested: onReportRequested,
              );

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: mainContent.mapSection),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: mainContent.sideSection),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        mainContent.mapSection,
                        const SizedBox(height: 18),
                        mainContent.sideSection,
                      ],
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MainContent {
  _MainContent({
    required this.theme,
    required this.selectedStop,
    required this.busesAtStop,
    required this.allStops,
    required this.selectedStopId,
    required this.onStopTap,
    required this.onBusTap,
    required this.onReportRequested,
  });

  final ThemeData theme;
  final BusStop? selectedStop;
  final List<Bus> busesAtStop;
  final List<BusStop> allStops;
  final String? selectedStopId;
  final ValueChanged<BusStop> onStopTap;
  final ValueChanged<Bus> onBusTap;
  final ValueChanged<Bus> onReportRequested;

  Widget get mapSection => MockTransitMap(
        buses: busesAtStop,
        stops: allStops,
        selectedStopId: selectedStopId,
        onStopTap: onStopTap,
        onBusTap: onBusTap,
      );

  Widget get sideSection => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedStopCard(
            theme: theme,
            stop: selectedStop,
          ),
          const SizedBox(height: 16),
          Text(
            'Bu duraktan geçen otobüsler',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...busesAtStop.map(
            (bus) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: BusDensityCard(
                bus: bus,
                stop: selectedStop ?? allStops.first,
                onTap: () => onBusTap(bus),
                onReport: () => onReportRequested(bus),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const _LegendCard(),
        ],
      );
}

class _SelectedStopCard extends StatelessWidget {
  const _SelectedStopCard({
    required this.theme,
    required this.stop,
  });

  final ThemeData theme;
  final BusStop? stop;

  @override
  Widget build(BuildContext context) {
    if (stop == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seçilen durak',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              stop!.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              stop!.area,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stop!.busLines.isEmpty
                  ? [const Chip(label: Text('Hat bilgisi yok'))]
                  : stop!.busLines
                      .map((line) => Chip(label: Text(line)))
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yoğunluk renkleri',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _LegendDot(label: 'Boş', color: Color(0xFF2E7D32)),
                _LegendDot(label: 'Orta', color: Color(0xFFF9A825)),
                _LegendDot(label: 'Kalabalık', color: Color(0xFFC62828)),
                _LegendDot(label: 'Tam dolu', color: Color(0xFF111111)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
