import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import '../providers/app_state.dart';
import '../providers/session_state.dart';
import 'auth_screen.dart';

const LatLng kKahramanmarasCenter = LatLng(37.5754, 36.9375);
const String kOpenStreetMapUserAgent = 'com.example.kahramanmaras_transport';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;

  BusStop? _selectedStop;
  Bus? _selectedBus;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      cancelPreviousAnimations: true,
    );
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final stops = _stopsForMap(state);
        final buses = state.buses.isEmpty ? _mockBuses() : state.buses;
        final isWide = MediaQuery.sizeOf(context).width >= 980;

        if (stops.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final selectedStop = _selectedStop ?? stops.first;
        final selectedBuses = _busesForStop(buses, selectedStop);

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _MapCanvas(
                  animatedMapController: _animatedMapController,
                  stops: stops,
                  selectedStop: selectedStop,
                  onStopTap: (stop) {
                    _selectStop(
                      stop: stop,
                      buses: buses,
                      animate: true,
                    );
                  },
                  onSearchSelection: (stop) {
                    _selectStop(
                      stop: stop,
                      buses: buses,
                      animate: true,
                    );
                  },
                ),
              ),
              VerticalDivider(color: Theme.of(context).dividerColor, width: 1),
              SizedBox(
                width: 392,
                child: _StopDetailsPanel(
                  stop: selectedStop,
                  buses: selectedBuses,
                  selectedBus: _selectedBus ?? _firstBusForStop(buses, selectedStop),
                  isSubmitting: _isSubmitting,
                  onBusSelected: (bus) => setState(() => _selectedBus = bus),
                  onReportLevelSelected: (level) => _submitReport(
                    context,
                    state,
                    selectedStop,
                    _selectedBus ?? _firstBusForStop(buses, selectedStop),
                    level,
                  ),
                ),
              ),
            ],
          );
        }

        return _MapCanvas(
          animatedMapController: _animatedMapController,
          stops: stops,
          selectedStop: selectedStop,
          onStopTap: (stop) async {
            _selectStop(
              stop: stop,
              buses: buses,
              animate: true,
            );

            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) {
                return _StopDetailsBottomSheet(
                  stop: stop,
                  buses: _busesForStop(buses, stop),
                  selectedBus: _selectedBus ?? _firstBusForStop(buses, stop),
                  isSubmitting: _isSubmitting,
                  onBusSelected: (bus) => setState(() => _selectedBus = bus),
                  onReportLevelSelected: (level) => _submitReport(
                    context,
                    state,
                    stop,
                    _selectedBus ?? _firstBusForStop(buses, stop),
                    level,
                  ),
                );
              },
            );
          },
          onSearchSelection: (stop) {
            _selectStop(
              stop: stop,
              buses: buses,
              animate: true,
            );
          },
        );
      },
    );
  }

  void _selectStop({
    required BusStop stop,
    required List<Bus> buses,
    required bool animate,
  }) {
    setState(() {
      _selectedStop = stop;
      _selectedBus = _firstBusForStop(buses, stop);
    });

    if (animate) {
      _animatedMapController.centerOnPoint(
        LatLng(stop.latitude, stop.longitude),
        zoom: 15,
      );
    }
  }

  List<BusStop> _stopsForMap(AppState state) {
    final apiStops = state.stops
        .where((stop) => stop.latitude != 0 || stop.longitude != 0)
        .toList();
    return apiStops.isNotEmpty ? apiStops : _mockStops();
  }

  List<Bus> _mockBuses() {
    return [
      Bus(
        id: 'mock-h24',
        routeNumber: 'H24',
        routeName: 'H24',
        origin: 'Kahramanmaraş Otogarı',
        destination: 'KSÜ Avşar Kampüsü',
        currentStopName: 'Piazza AVM',
        nextStopName: 'Binevler',
        occupancyPercent: 78,
        densityLevel: DensityLevel.crowded,
        etaMinutes: 4,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
        popularityScore: 91,
      ),
      Bus(
        id: 'mock-h26',
        routeNumber: 'H26',
        routeName: 'H26',
        origin: 'Kahramanmaraş Otogarı',
        destination: 'Hasancıklı',
        currentStopName: 'Tekerek Yolu',
        nextStopName: 'Şelale Park',
        occupancyPercent: 52,
        densityLevel: DensityLevel.moderate,
        etaMinutes: 7,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
        popularityScore: 73,
      ),
    ];
  }

  List<BusStop> _mockStops() {
    return const [
      BusStop(
        id: 'stop-otogar',
        name: 'Kahramanmaraş Otogarı',
        area: 'Onikişubat',
        distanceKm: 0.0,
        currentDensity: DensityLevel.moderate,
        latitude: 37.58514,
        longitude: 36.95518,
        busLines: ['H24', 'H26'],
      ),
      BusStop(
        id: 'stop-piazza',
        name: 'Piazza AVM',
        area: 'Onikişubat',
        distanceKm: 0.0,
        currentDensity: DensityLevel.crowded,
        latitude: 37.56594,
        longitude: 36.93748,
        busLines: ['H24', 'H13'],
      ),
      BusStop(
        id: 'stop-binevler',
        name: 'Binevler',
        area: 'Onikişubat',
        distanceKm: 0.0,
        currentDensity: DensityLevel.moderate,
        latitude: 37.55388,
        longitude: 36.94582,
        busLines: ['H24'],
      ),
      BusStop(
        id: 'stop-tekerek',
        name: 'Tekerek Yolu',
        area: 'Onikişubat',
        distanceKm: 0.0,
        currentDensity: DensityLevel.empty,
        latitude: 37.56093,
        longitude: 36.94418,
        busLines: ['H26'],
      ),
      BusStop(
        id: 'stop-selale',
        name: 'Şelale Park',
        area: 'Onikişubat',
        distanceKm: 0.0,
        currentDensity: DensityLevel.moderate,
        latitude: 37.57251,
        longitude: 36.95041,
        busLines: ['H24', 'H26'],
      ),
    ];
  }

  List<Bus> _busesForStop(List<Bus> buses, BusStop stop) {
    final filtered = buses.where((bus) => stop.busLines.contains(bus.routeNumber)).toList();
    return filtered.isNotEmpty ? filtered : buses;
  }

  Bus _firstBusForStop(List<Bus> buses, BusStop stop) {
    return _busesForStop(buses, stop).first;
  }

  Future<void> _submitReport(
    BuildContext context,
    AppState state,
    BusStop stop,
    Bus bus,
    DensityLevel level,
  ) async {
    if (_isSubmitting) return;

    final session = context.read<SessionState>();
    if (!session.isLoggedIn) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor göndermek için giriş yapmalısın.')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final position = await _tryGetPosition();
      await state.submitReport(
        bus: bus,
        stop: stop,
        densityLevel: level,
        userLat: position?.latitude,
        userLon: position?.longitude,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapor gönderildi: ${stop.name} - ${level.label}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<Position?> _tryGetPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {
      return null;
    }
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.animatedMapController,
    required this.stops,
    required this.selectedStop,
    required this.onStopTap,
    required this.onSearchSelection,
  });

  final AnimatedMapController animatedMapController;
  final List<BusStop> stops;
  final BusStop selectedStop;
  final ValueChanged<BusStop> onStopTap;
  final ValueChanged<BusStop> onSearchSelection;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: animatedMapController.mapController,
          options: const MapOptions(
            initialCenter: kKahramanmarasCenter,
            initialZoom: 13.2,
            minZoom: 11,
            maxZoom: 18,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: kOpenStreetMapUserAgent,
            ),
            MarkerLayer(
              markers: stops
                  .map(
                    (stop) => Marker(
                      point: LatLng(stop.latitude, stop.longitude),
                      width: 34,
                      height: 34,
                      child: GestureDetector(
                        onTap: () => onStopTap(stop),
                        child: _StopMarker(selected: stop.id == selectedStop.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        const Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: _GlassCaption(
              title: 'Kahramanmaraş Harita',
              subtitle: 'Duraklara dokun ya da ara ve sağ paneli kullan.',
            ),
          ),
        ),
        Positioned(
          top: 88,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: _StopSearchBar(
              stops: stops,
              onSelected: onSearchSelection,
            ),
          ),
        ),
      ],
    );
  }
}

class _StopSearchBar extends StatefulWidget {
  const _StopSearchBar({
    required this.stops,
    required this.onSelected,
  });

  final List<BusStop> stops;
  final ValueChanged<BusStop> onSelected;

  @override
  State<_StopSearchBar> createState() => _StopSearchBarState();
}

class _StopSearchBarState extends State<_StopSearchBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Autocomplete<BusStop>(
          displayStringForOption: (stop) => stop.name,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) {
              return const Iterable<BusStop>.empty();
            }

            return widget.stops.where(
              (stop) => stop.name.toLowerCase().contains(query),
            );
          },
          onSelected: widget.onSelected,
          optionsViewBuilder: (context, onSelected, options) {
            final optionsList = options.toList();
            if (optionsList.isEmpty) {
              return const SizedBox.shrink();
            }

            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                color: theme.colorScheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280, maxWidth: 560),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: optionsList.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, index) {
                      final stop = optionsList[index];
                      return ListTile(
                        title: Text(stop.name),
                        subtitle: Text(stop.area),
                        onTap: () => onSelected(stop),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return SearchBar(
              controller: controller,
              focusNode: focusNode,
              hintText: 'Durak ara',
              leading: const Icon(Icons.search_rounded),
              padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              onTap: () {
                if (!focusNode.hasFocus) {
                  focusNode.requestFocus();
                }
              },
              onChanged: (_) => setState(() {}),
            );
          },
        ),
      ),
    );
  }
}

class _GlassCaption extends StatelessWidget {
  const _GlassCaption({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFE53935) : const Color(0xFFC62828);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: selected ? 18 : 14,
          height: selected ? 18 : 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}

class _StopDetailsPanel extends StatelessWidget {
  const _StopDetailsPanel({
    required this.stop,
    required this.buses,
    required this.selectedBus,
    required this.isSubmitting,
    required this.onBusSelected,
    required this.onReportLevelSelected,
  });

  final BusStop stop;
  final List<Bus> buses;
  final Bus selectedBus;
  final bool isSubmitting;
  final ValueChanged<Bus> onBusSelected;
  final ValueChanged<DensityLevel> onReportLevelSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              stop.name,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${stop.latitude.toStringAsFixed(5)}, ${stop.longitude.toStringAsFixed(5)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              'Bu duraktan geçen hatlar',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...buses.map(
              (bus) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BusTile(
                  bus: bus,
                  selected: bus.id == selectedBus.id,
                  onTap: () => onBusSelected(bus),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Yoğunluk raporu',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.95,
              children: DensityLevel.values
                  .map(
                    (level) => FilledButton.tonal(
                      onPressed: isSubmitting ? null : () => onReportLevelSelected(level),
                      style: FilledButton.styleFrom(
                        backgroundColor: level.color.withValues(alpha: 0.12),
                        foregroundColor: level.color,
                      ),
                      child: Text(level.label),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopDetailsBottomSheet extends StatelessWidget {
  const _StopDetailsBottomSheet({
    required this.stop,
    required this.buses,
    required this.selectedBus,
    required this.isSubmitting,
    required this.onBusSelected,
    required this.onReportLevelSelected,
  });

  final BusStop stop;
  final List<Bus> buses;
  final Bus selectedBus;
  final bool isSubmitting;
  final ValueChanged<Bus> onBusSelected;
  final ValueChanged<DensityLevel> onReportLevelSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StopDetailsPanel(
                stop: stop,
                buses: buses,
                selectedBus: selectedBus,
                isSubmitting: isSubmitting,
                onBusSelected: onBusSelected,
                onReportLevelSelected: onReportLevelSelected,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusTile extends StatelessWidget {
  const _BusTile({
    required this.bus,
    required this.selected,
    required this.onTap,
  });

  final Bus bus;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bus.densityLevel.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  bus.routeNumber,
                  style: TextStyle(
                    color: bus.densityLevel.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bus.routeTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
