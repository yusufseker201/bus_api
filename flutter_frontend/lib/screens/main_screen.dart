import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import '../models/density_report.dart';
import '../providers/app_state.dart';
import '../providers/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/density_level_badge.dart';
import '../widgets/mock_transit_map.dart';
import '../widgets/report_density_sheet.dart';
import 'auth_screen.dart';
import 'map_screen.dart';
import 'profile_tab.dart';
import 'route_details_screen.dart';

enum AppSection {
  dashboard,
  map,
  profile,
}

extension AppSectionX on AppSection {
  String get label => switch (this) {
        AppSection.dashboard => 'Panel',
        AppSection.map => 'Harita',
        AppSection.profile => 'Profil',
      };

  IconData get icon => switch (this) {
        AppSection.dashboard => Icons.dashboard_customize_rounded,
        AppSection.map => Icons.map_rounded,
        AppSection.profile => Icons.person_rounded,
      };
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialSection = AppSection.dashboard});

  final AppSection initialSection;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late AppSection _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SessionState, AppState>(
      builder: (context, session, state, _) {
        if (!session.isReady ||
            state.isLoading && state.buses.isEmpty && state.stops.isEmpty) {
          return const _LoadingScaffold();
        }

        if (state.errorMessage != null &&
            state.buses.isEmpty &&
            state.stops.isEmpty) {
          return _ErrorScaffold(
            message: state.errorMessage!,
            onRetry: state.loadInitialData,
          );
        }

        return Scaffold(
          appBar: _MainAppBar(
            section: _section,
            isLoggedIn: session.isLoggedIn,
            userLabel: state.profile?.userName ?? session.email ?? 'Giriş',
            onRefresh: state.loadInitialData,
            onAuthPressed: () => _handleAuthAction(session),
          ),
          backgroundColor: AppTheme.shell,
          bottomNavigationBar: MediaQuery.sizeOf(context).width < 720
              ? NavigationBar(
                  selectedIndex: AppSection.values.indexOf(_section),
                  onDestinationSelected: (index) {
                    setState(() => _section = AppSection.values[index]);
                  },
                  destinations: AppSection.values
                      .map(
                        (section) => NavigationDestination(
                          icon: Icon(section.icon),
                          label: section.label,
                        ),
                      )
                      .toList(),
                )
              : null,
          body: Column(
            children: [
              if (MediaQuery.sizeOf(context).width >= 720)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: _SectionSelector(
                    current: _section,
                    onChanged: (section) => setState(() => _section = section),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: switch (_section) {
                    AppSection.dashboard => _DashboardView(
                        key: const ValueKey('dashboard'),
                        state: state,
                        session: session,
                        onBusTap: _openRouteDetails,
                        onReportTap: _openReportSheet,
                      ),
                    AppSection.map => const MapScreen(key: ValueKey('map')),
                    AppSection.profile =>
                      const ProfileTab(key: ValueKey('profile')),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAuthAction(SessionState session) async {
    if (session.isLoggedIn) {
      setState(() => _section = AppSection.profile);
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AuthScreen()),
    );
    if (!mounted || result != true) return;
    await context.read<AppState>().loadInitialData();
  }

  Future<void> _openRouteDetails(Bus bus) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RouteDetailsScreen(bus: bus),
      ),
    );
  }

  Future<void> _openReportSheet(Bus bus) async {
    final appState = context.read<AppState>();
    final stop = appState.nearestStopForBus(bus);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDensitySheet(bus: bus, stop: stop),
    );
  }
}

class _MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MainAppBar({
    required this.section,
    required this.isLoggedIn,
    required this.userLabel,
    required this.onRefresh,
    required this.onAuthPressed,
  });

  final AppSection section;
  final bool isLoggedIn;
  final String userLabel;
  final Future<void> Function() onRefresh;
  final VoidCallback onAuthPressed;

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: 92,
      titleSpacing: 22,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Kahramanmaraş Otobüs'),
          const SizedBox(height: 4),
          Text(
            switch (section) {
              AppSection.dashboard => 'Canlı hat, durak ve yoğunluk paneli',
              AppSection.map => 'Gerçek koordinatlarla durak takibi',
              AppSection.profile => 'Topluluk profilin ve katkıların',
            },
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Yenile',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Center(
            child: TextButton.icon(
              onPressed: onAuthPressed,
              icon: Icon(isLoggedIn
                  ? Icons.verified_user_rounded
                  : Icons.login_rounded),
              label: Text(isLoggedIn ? _shortUserLabel(userLabel) : 'Giriş'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.deepTeal,
                backgroundColor: Colors.white.withValues(alpha: 0.94),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _shortUserLabel(String value) {
    if (value.length <= 16) {
      return value;
    }
    return '${value.substring(0, 15)}...';
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({
    required this.current,
    required this.onChanged,
  });

  final AppSection current;
  final ValueChanged<AppSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: AppSection.values.map((section) {
          final selected = section == current;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onChanged(section),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.mint : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(section.icon,
                          size: 18,
                          color: selected ? AppTheme.deepTeal : AppTheme.muted),
                      const SizedBox(width: 8),
                      Text(
                        section.label,
                        style: TextStyle(
                          color: selected ? AppTheme.deepTeal : AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    super.key,
    required this.state,
    required this.session,
    required this.onBusTap,
    required this.onReportTap,
  });

  final AppState state;
  final SessionState session;
  final ValueChanged<Bus> onBusTap;
  final ValueChanged<Bus> onReportTap;

  @override
  Widget build(BuildContext context) {
    final featuredReports = state.liveReports.isNotEmpty
        ? state.liveReports
        : state.profile?.recentReports ?? const <DensityReport>[];
    final selectedStop = state.selectedStop ??
        (state.stops.isNotEmpty ? state.stops.first : null);
    final routeItems = state.buses.take(8).toList();
    final stopItems = state.stops.take(8).toList();

    return RefreshIndicator(
      onRefresh: state.loadInitialData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StatsRow(
            stopCount: state.stops.length,
            busCount: state.buses.length,
            liveCount: featuredReports.length,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1180;
              final extraWide = constraints.maxWidth >= 1450;

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: extraWide ? 6 : 5,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 430,
                            child: _MapPanel(
                              state: state,
                              onBusTap: onBusTap,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SelectedStopPanel(
                            stop: selectedStop,
                            isLoggedIn: session.isLoggedIn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _SectionCard(
                        title: 'Hatlar',
                        subtitle: 'Aktif hat akışı',
                        child: _RouteList(
                          buses: routeItems,
                          nearestStopForBus: state.nearestStopForBus,
                          onBusTap: onBusTap,
                          onReportTap: onReportTap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _SectionCard(
                        title: 'Duraklar',
                        subtitle: 'Yoğunluk odaklı görünüm',
                        child: _StopList(
                          stops: stopItems,
                          selectedStopId: selectedStop?.id,
                          onSelected: state.selectStop,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _SectionCard(
                        title: 'Canlı Bildirimler',
                        subtitle: 'Topluluk akışı',
                        child: _LiveReportList(reports: featuredReports),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 360,
                    child: _MapPanel(
                      state: state,
                      onBusTap: onBusTap,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SelectedStopPanel(
                    stop: selectedStop,
                    isLoggedIn: session.isLoggedIn,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Hatlar',
                    subtitle: 'Aktif hat akışı',
                    child: _RouteList(
                      buses: routeItems,
                      nearestStopForBus: state.nearestStopForBus,
                      onBusTap: onBusTap,
                      onReportTap: onReportTap,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Duraklar',
                    subtitle: 'Yoğunluk odaklı görünüm',
                    child: _StopList(
                      stops: stopItems,
                      selectedStopId: selectedStop?.id,
                      onSelected: state.selectStop,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Canlı Bildirimler',
                    subtitle: 'Topluluk akışı',
                    child: _LiveReportList(reports: featuredReports),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stopCount,
    required this.busCount,
    required this.liveCount,
  });

  final int stopCount;
  final int busCount;
  final int liveCount;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;

    final children = [
      _StatPill(
        icon: Icons.location_on_outlined,
        value: '$stopCount',
        label: 'Konumlu Durak',
        tint: const Color(0xFFE8F7F3),
        iconColor: AppTheme.deepTeal,
      ),
      _StatPill(
        icon: Icons.route_rounded,
        value: '$busCount',
        label: 'Aktif Hat',
        tint: const Color(0xFFEFF6F1),
        iconColor: const Color(0xFF317C68),
      ),
      _StatPill(
        icon: Icons.notifications_active_outlined,
        value: '$liveCount',
        label: 'Canlı Bildirim',
        tint: const Color(0xFFFFF3DA),
        iconColor: const Color(0xFFC88A1E),
      ),
    ];

    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i != children.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          children.map((child) => SizedBox(width: 220, child: child)).toList(),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.state,
    required this.onBusTap,
  });

  final AppState state;
  final ValueChanged<Bus> onBusTap;

  @override
  Widget build(BuildContext context) {
    return MockTransitMap(
      buses: state.buses,
      stops: state.stops,
      selectedStopId: state.selectedStop?.id,
      onStopTap: state.selectStop,
      onBusTap: onBusTap,
    );
  }
}

class _SelectedStopPanel extends StatelessWidget {
  const _SelectedStopPanel({
    required this.stop,
    required this.isLoggedIn,
  });

  final BusStop? stop;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow,
      ),
      child: stop == null
          ? Text(
              'Durak seçildiğinde burada özet bilgisi görünecek.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop!.name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stop!.area.isEmpty
                                ? 'Kahramanmaraş merkezinde aktif durak'
                                : stop!.area,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DensityLevelBadge(
                        level: stop!.currentDensity, compact: true),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...stop!.busLines.take(6).map(
                          (line) => Chip(
                            label: Text(line),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    Chip(
                      label: Text(isLoggedIn
                          ? 'Rapor göndermeye hazır'
                          : 'Rapor için giriş gerekli'),
                      avatar: Icon(
                        isLoggedIn
                            ? Icons.check_circle_outline_rounded
                            : Icons.login_rounded,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({
    required this.buses,
    required this.nearestStopForBus,
    required this.onBusTap,
    required this.onReportTap,
  });

  final List<Bus> buses;
  final BusStop Function(Bus bus) nearestStopForBus;
  final ValueChanged<Bus> onBusTap;
  final ValueChanged<Bus> onReportTap;

  @override
  Widget build(BuildContext context) {
    if (buses.isEmpty) {
      return const _EmptyPanelMessage(message: 'Henüz aktif hat verisi yok.');
    }

    return Column(
      children: buses
          .map(
            (bus) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RouteTile(
                bus: bus,
                stop: nearestStopForBus(bus),
                onTap: () => onBusTap(bus),
                onReportTap: () => onReportTap(bus),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.bus,
    required this.stop,
    required this.onTap,
    required this.onReportTap,
  });

  final Bus bus;
  final BusStop stop;
  final VoidCallback onTap;
  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFFDFEFD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4F1EC)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  bus.routeNumber,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.deepTeal,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bus.origin} - ${bus.destination}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Son rapor: ${stop.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onReportTap,
                    icon: const Icon(Icons.post_add_rounded, size: 18),
                    label: const Text('Raporla'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.mint,
                      foregroundColor: AppTheme.deepTeal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DensityLevelBadge(level: bus.densityLevel, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopList extends StatelessWidget {
  const _StopList({
    required this.stops,
    required this.selectedStopId,
    required this.onSelected,
  });

  final List<BusStop> stops;
  final String? selectedStopId;
  final ValueChanged<BusStop> onSelected;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return const _EmptyPanelMessage(message: 'Durak verisi bulunamadı.');
    }

    return Column(
      children: stops
          .map(
            (stop) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StopTile(
                stop: stop,
                selected: stop.id == selectedStopId,
                onTap: () => onSelected(stop),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.selected,
    required this.onTap,
  });

  final BusStop stop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? const Color(0xFFF4FBF8) : const Color(0xFFFDFEFD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? const Color(0xFFBDE6DB) : const Color(0xFFE4F1EC),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop.busLines.isEmpty
                          ? 'Hat bilgisi eklenmemiş'
                          : 'Hatlar: ${stop.busLines.take(4).join(', ')}${stop.busLines.length > 4 ? '...' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DensityLevelBadge(level: stop.currentDensity, compact: true),
                  const SizedBox(height: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected ? AppTheme.teal : AppTheme.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveReportList extends StatelessWidget {
  const _LiveReportList({required this.reports});

  final List<DensityReport> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _EmptyPanelMessage(
          message: 'Yeni kullanıcı bildirimi bekleniyor.');
    }

    return Column(
      children: reports
          .take(10)
          .map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LiveReportTile(report: report),
            ),
          )
          .toList(),
    );
  }
}

class _LiveReportTile extends StatelessWidget {
  const _LiveReportTile({required this.report});

  final DensityReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initialsFor(report.reporterName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4F1EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: report.densityLevel.color.withValues(alpha: 0.16),
            child: Text(
              initials,
              style: TextStyle(
                color: report.densityLevel.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.displayLine}: ${report.densityLevel.label}',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  report.stopName.isEmpty
                      ? report.reporterName
                      : '${report.stopName} • ${report.reporterName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatReportTime(report.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            report.isActive
                ? Icons.file_download_done_rounded
                : Icons.schedule_rounded,
            color: report.isActive ? AppTheme.teal : AppTheme.muted,
            size: 18,
          ),
        ],
      ),
    );
  }

  String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'T';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatReportTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} dk önce';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    }
    return '${dateTime.day.toString().padLeft(2, '0')} ${_monthName(dateTime.month)}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return months[month - 1];
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.shell,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.shell,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 44, color: AppTheme.deepTeal),
                const SizedBox(height: 14),
                Text(
                  'Veriler alınamadı',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
