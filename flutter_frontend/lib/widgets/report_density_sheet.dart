import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bus.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import '../providers/app_state.dart';
import 'density_level_badge.dart';

class ReportDensitySheet extends StatefulWidget {
  const ReportDensitySheet({
    super.key,
    required this.bus,
    required this.stop,
  });

  final Bus bus;
  final BusStop stop;

  @override
  State<ReportDensitySheet> createState() => _ReportDensitySheetState();
}

class _ReportDensitySheetState extends State<ReportDensitySheet> {
  DensityLevel? _selectedLevel;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Yoğunluk bildir',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              DensityLevelBadge(level: widget.bus.densityLevel, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.bus.displayName} • ${widget.stop.name}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konum doğrulaması geçti. Django API daha sonra GPS ve yakınlık kontrolü yapacak.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yoğunluk seç',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = isWide || constraints.maxWidth > 520 ? 2 : 1;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: DensityLevel.values.map((level) {
                  return SizedBox(
                    width: columns == 2
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth,
                    child: _DensityChoiceButton(
                      level: level,
                      selected: _selectedLevel == level,
                      onPressed: () => setState(() => _selectedLevel = level),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _submitting
                ? null
                : _selectedLevel == null
                    ? null
                    : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gönder'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final selectedLevel = _selectedLevel;
    if (selectedLevel == null) return;

    setState(() => _submitting = true);
    await context.read<AppState>().submitReport(
          bus: widget.bus,
          stop: widget.stop,
          densityLevel: selectedLevel,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Rapor gönderildi. +${selectedLevel.reportPoints} puan kazandınız.'),
      ),
    );
  }
}

class _DensityChoiceButton extends StatelessWidget {
  const _DensityChoiceButton({
    required this.level,
    required this.selected,
    required this.onPressed,
  });

  final DensityLevel level;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = level.color;
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? color.withValues(alpha: 0.16)
            : theme.colorScheme.surface,
        side: BorderSide(
            color: selected ? color : theme.colorScheme.outlineVariant,
            width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              level.shortLabel.substring(0, 1),
              style: TextStyle(
                color: level.contentColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            level.label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Seç',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
