import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/density_report.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import 'map_screen.dart';
import 'profile_tab.dart';

enum AppSection {
  home,
  map,
  profile,
}

extension AppSectionX on AppSection {
  String get title => switch (this) {
        AppSection.home => 'Ana Sayfa',
        AppSection.map => 'Harita',
        AppSection.profile => 'Profil',
      };

  IconData get icon => switch (this) {
        AppSection.home => Icons.home_outlined,
        AppSection.map => Icons.map_outlined,
        AppSection.profile => Icons.person_outline,
      };

  IconData get selectedIcon => switch (this) {
        AppSection.home => Icons.home_rounded,
        AppSection.map => Icons.map_rounded,
        AppSection.profile => Icons.person_rounded,
      };
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialSection = AppSection.home});

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
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.errorMessage != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F7FB),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 44),
                          const SizedBox(height: 12),
                          Text(
                            'Veriler alınamadı',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: state.loadInitialData,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final isDesktop = MediaQuery.sizeOf(context).width >= 980;
        final content = _buildContent(state);

        if (isDesktop) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F7FB),
            body: Row(
              children: [
                _Sidebar(
                  section: _section,
                  onSelected: _handleSectionSelected,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: content,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: AppBar(
            title: Text(_section.title),
            centerTitle: false,
          ),
          drawer: Drawer(
            child: SafeArea(
              child: _Sidebar(
                section: _section,
                onSelected: (section) {
                  Navigator.of(context).pop();
                  _handleSectionSelected(section);
                },
                compact: true,
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: content,
          ),
        );
      },
    );
  }

  void _handleSectionSelected(AppSection section) {
    setState(() => _section = section);
  }

  Widget _buildContent(AppState state) {
    return switch (_section) {
      AppSection.home => DashboardScreen(
          key: const ValueKey('home'),
          profile: state.profile ?? _fallbackProfile(),
          stopCount: state.stops.isEmpty ? _fallbackStopCount : state.stops.length,
          busCount: state.buses.isEmpty ? _fallbackBusCount : state.buses.length,
        ),
      AppSection.map => const MapScreen(),
      AppSection.profile => const ProfileTab(),
    };
  }

  UserProfile _fallbackProfile() {
    return const UserProfile(
      userName: 'Misafir',
      totalPoints: 120,
      currentRank: 'Durak Kaşifi',
      badgeName: 'Topluluk Raporcusu',
      recentReports: <DensityReport>[],
    );
  }

  int get _fallbackStopCount => 5;
  int get _fallbackBusCount => 2;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.section,
    required this.onSelected,
    this.compact = false,
  });

  final AppSection section;
  final ValueChanged<AppSection> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <AppSection>[
      AppSection.home,
      AppSection.map,
      AppSection.profile,
    ];

    if (compact) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SidebarHeader(compact: true),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SidebarTile(
                section: item,
                selected: item == section,
                onTap: () => onSelected(item),
                compact: true,
              ),
            ),
          ),
        ],
      );
    }

    return NavigationRail(
      selectedIndex: items.indexOf(section),
      onDestinationSelected: (index) => onSelected(items[index]),
      labelType: NavigationRailLabelType.all,
      backgroundColor: theme.colorScheme.surface,
      leading: const Padding(
        padding: EdgeInsets.all(16),
        child: _SidebarHeader(),
      ),
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(item.title),
            ),
          )
          .toList(),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: compact ? 40 : 48,
          height: compact ? 40 : 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_bus_rounded, color: Colors.white),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kahramanmaraş',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Toplu Taşıma Paneli',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.section,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = ListTile(
      selected: selected,
      leading: Icon(selected ? section.selectedIcon : section.icon),
      title: Text(section.title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
      selectedColor: theme.colorScheme.primary,
    );

    if (compact) {
      return child;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: child,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.profile,
    required this.stopCount,
    required this.busCount,
  });

  final UserProfile profile;
  final int stopCount;
  final int busCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeroCard(profile: profile),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : 2;
              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: 1.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    title: 'Durak',
                    value: '$stopCount',
                    icon: Icons.place_rounded,
                  ),
                  _StatCard(
                    title: 'Hat',
                    value: '$busCount',
                    icon: Icons.directions_bus_rounded,
                  ),
                  _StatCard(
                    title: 'Puan',
                    value: '${profile.totalPoints}',
                    icon: Icons.stars_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Hızlı Erişim',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    child: Icon(Icons.map_rounded, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Haritaya geçip duraklarda yoğunluk raporu gönderebilirsin.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün ne yapabilirsin?',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  const _TipItem(
                    icon: Icons.map_rounded,
                    title: 'Haritaya geç',
                    description: 'Durakları gerçek koordinatlarla incele ve yoğunluk bildir.',
                  ),
                  const _TipItem(
                    icon: Icons.person_rounded,
                    title: 'Profilini kontrol et',
                    description: 'Puanlarını ve son raporlarını gözden geçir.',
                  ),
                  const _TipItem(
                    icon: Icons.verified_rounded,
                    title: 'Veri kalitesini yükselt',
                    description: 'Doğru raporlar topluluk deneyimini güçlendirir.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş geldin, ${profile.userName}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kahramanmaraş toplu taşıma yoğunluğunu gerçek zamanlı izleyebilir, durak bazlı rapor gönderebilir ve profilini büyütebilirsin.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
