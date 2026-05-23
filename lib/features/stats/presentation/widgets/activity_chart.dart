import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/activity_log_provider.dart';

/// Histogramme simple des N derniers jours d'activité (mode "GitHub contrib").
class ActivityChart extends ConsumerWidget {
  const ActivityChart({super.key, this.days = 30});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    ref.watch(activityLogProvider);
    final log = ref.read(activityLogProvider.notifier);
    final data = log.lastDays(days);
    final maxVal = data.fold<int>(0, (m, d) => d.count > m ? d.count : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Activité — $days derniers jours',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  'Max $maxVal',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 80,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth =
                      (constraints.maxWidth - (days - 1) * 2) / days;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final entry in data) ...[
                        Tooltip(
                          message:
                              '${_short(entry.date)} — ${entry.count} verset${entry.count > 1 ? "s" : ""}',
                          child: Container(
                            width: barWidth,
                            height: maxVal == 0
                                ? 4
                                : 4 + (entry.count / maxVal) * 76,
                            decoration: BoxDecoration(
                              color: entry.count == 0
                                  ? AppColors.srs0
                                  : _color(entry.count, maxVal),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXs,
                              ),
                            ),
                          ),
                        ),
                        if (entry != data.last) const SizedBox(width: 2),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _short(data.first.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Aujourd\'hui',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _color(int count, int max) {
    final ratio = max == 0 ? 0 : count / max;
    if (ratio >= 0.75) return AppColors.srs5;
    if (ratio >= 0.5) return AppColors.srs4;
    if (ratio >= 0.25) return AppColors.srs3;
    return AppColors.srs2;
  }

  String _short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
