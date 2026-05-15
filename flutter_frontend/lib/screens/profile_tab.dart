import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/session_state.dart';
import 'auth_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<SessionState, AppState>(
      builder: (context, session, state, _) {
        if (!session.isLoggedIn) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Giriş gerekli',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text('Profilini ve rapor geçmişini görmek için giriş yapmalısın.'),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
                          );
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Giriş Yap'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final profile = state.profile;
        final displayName = profile?.userName ?? (session.email ?? 'Kullanıcı');

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.person, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Yenile',
                      onPressed: state.loadInitialData,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Toplam puan',
                    value: '${profile?.totalPoints ?? 0}',
                    icon: Icons.stars_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Rütbe',
                    value: profile?.currentRank ?? '-',
                    icon: Icons.verified_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son raporlar',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    if (profile == null)
                      Text(
                        'Profil verisi alınamadı. Yenilemeyi deneyin.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      )
                    else if (profile.recentReports.isEmpty)
                      Text(
                        'Henüz rapor yok.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      )
                    else
                      ...profile.recentReports.map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: r.densityLevel.color.withValues(alpha: 0.12),
                            child: Icon(Icons.directions_bus_rounded, color: r.densityLevel.color),
                          ),
                          title: Text('${r.busRouteNumber} • ${r.stopName}'),
                          subtitle: Text('${r.densityLevel.label} • ${r.createdAt}'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await session.logout();
                        if (!context.mounted) return;
                        await context.read<AppState>().loadInitialData();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
