import 'package:flutter/material.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.versesToMemorize,
    required this.versesToReview,
    required this.streakDays,
    this.onEdit,
    this.onDelete,
  });

  final int versesToMemorize;
  final int versesToReview;
  final int streakDays;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.currentStreak(streakDays),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 20),
                    tooltip: 'Options du plan',
                    onSelected: (action) {
                      if (action == 'edit' && onEdit != null) onEdit!();
                      if (action == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Modifier le plan'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Supprimer le plan'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Metric(
              label: l10n.versesToMemorize,
              value: versesToMemorize,
              accent: theme.colorScheme.primary,
            ),
            const Divider(height: AppSpacing.xxl),
            _Metric(
              label: l10n.versesToReview,
              value: versesToReview,
              accent: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        Text(
          '$value',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
