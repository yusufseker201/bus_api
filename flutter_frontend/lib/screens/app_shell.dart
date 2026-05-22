import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bus.dart';
import '../providers/app_state.dart';
import '../widgets/report_density_sheet.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'route_details_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;
    final pages = [
      HomeScreen(
        onBusSelected: _openRouteDetails,
        onReportRequested: _openReportSheet,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Kahramanmaraş Toplu Taşıma' : 'Profilim'),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Yoğunluk bildir',
              icon: const Icon(Icons.add_alert_outlined),
              onPressed: () {
                final bus = context.read<AppState>().selectedBus;
                if (bus != null) _openReportSheet(bus);
              },
            ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Ana sayfa'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Profil'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_index]),
              ],
            )
          : IndexedStack(index: _index, children: pages),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Ana sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }

  Future<void> _openRouteDetails(Bus bus) async {
    context.read<AppState>().selectBus(bus);
    await Navigator.of(context).pushNamed(
      RouteDetailsScreen.routeName,
      arguments: bus,
    );
  }

  Future<void> _openReportSheet(Bus bus) async {
    final appState = context.read<AppState>();
    final stop = appState.nearestStopForBus(bus);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReportDensitySheet(bus: bus, stop: stop),
    );
  }
}
