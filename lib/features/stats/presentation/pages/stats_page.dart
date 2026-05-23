import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../hifz/domain/memorization_status.dart';
import '../../../hifz/presentation/providers/memorization_provider.dart';
import '../providers/activity_log_provider.dart';
import '../widgets/activity_chart.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    ref.watch(activityLogProvider);
    ref.watch(memorizationProvider);
    final log = ref.read(activityLogProvider.notifier);
    final memo = ref.read(memorizationProvider.notifier);

    final streak = log.currentStreak();
    final best = log.bestStreak();
    final activeDays = log.totalActiveDays;
    final totalLogs = log.totalVersesLogged;

    final memorized = memo.countByStatus(MemorizationStatus.memorized);
    final memorizing = memo.countByStatus(MemorizationStatus.memorizing);
    final needsReview = memo.countByStatus(MemorizationStatus.needsReview);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // KPIs en grille 2x2
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Série actuelle',
                  value: '$streak',
                  unit: streak > 1 ? 'jours' : 'jour',
                  icon: Icons.local_fire_department_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiCard(
                  label: 'Record',
                  value: '$best',
                  unit: best > 1 ? 'jours' : 'jour',
                  icon: Icons.emoji_events_outlined,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Jours actifs',
                  value: '$activeDays',
                  unit: '',
                  icon: Icons.calendar_today_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiCard(
                  label: 'Versets travaillés',
                  value: '$totalLogs',
                  unit: '',
                  icon: Icons.menu_book_outlined,
                  color: AppColors.srs4,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          const ActivityChart(days: 30),

          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Répartition des versets',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StatusBar(
                    label: 'Mémorisés',
                    value: memorized,
                    total: memorized + memorizing + needsReview,
                    color: AppColors.srs5,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatusBar(
                    label: 'En cours',
                    value: memorizing,
                    total: memorized + memorizing + needsReview,
                    color: AppColors.srs2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatusBar(
                    label: 'À revoir',
                    value: needsReview,
                    total: memorized + memorizing + needsReview,
                    color: AppColors.srs1,
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

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              '$value',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull / 2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor:
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
