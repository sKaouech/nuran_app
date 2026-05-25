import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/haptics.dart';
import '../../domain/memorization_status.dart';
import '../providers/memorization_provider.dart';

/// Bouton compact qui affiche et cycle le statut de mémorisation d'un verset.
class MemorizationButton extends ConsumerWidget {
  const MemorizationButton({super.key, required this.globalIndex});

  final int globalIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(memorizationProvider)[globalIndex] ??
        MemorizationStatus.notStarted;
    final controller = ref.read(memorizationProvider.notifier);

    return InkWell(
      onTap: () => _showPicker(context, controller),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: _bgColor(status),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(status), size: 14, color: _fgColor(status)),
            const SizedBox(width: 4),
            Text(
              _label(status),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _fgColor(status),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, MemorizationNotifier controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: MemorizationStatus.values.map((s) {
            return ListTile(
              leading: Icon(_icon(s), color: _fgColor(s)),
              title: Text(_label(s)),
              onTap: () {
                if (s == MemorizationStatus.memorized) {
                  Haptics.success();
                } else {
                  Haptics.light();
                }
                controller.setStatus(globalIndex, s);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _label(MemorizationStatus s) => switch (s) {
        MemorizationStatus.notStarted => 'Non commencé',
        MemorizationStatus.memorizing => 'En cours',
        MemorizationStatus.memorized => 'Mémorisé',
        MemorizationStatus.needsReview => 'À revoir',
      };

  IconData _icon(MemorizationStatus s) => switch (s) {
        MemorizationStatus.notStarted => Icons.circle_outlined,
        MemorizationStatus.memorizing => Icons.school_outlined,
        MemorizationStatus.memorized => Icons.check_circle,
        MemorizationStatus.needsReview => Icons.refresh,
      };

  Color _bgColor(MemorizationStatus s) => switch (s) {
        MemorizationStatus.notStarted => Colors.transparent,
        MemorizationStatus.memorizing => AppColors.srs2.withValues(alpha: 0.3),
        MemorizationStatus.memorized => AppColors.srs5.withValues(alpha: 0.25),
        MemorizationStatus.needsReview => AppColors.srs1.withValues(alpha: 0.3),
      };

  Color _fgColor(MemorizationStatus s) => switch (s) {
        MemorizationStatus.notStarted => Colors.grey,
        MemorizationStatus.memorizing => const Color(0xFF92400E),
        MemorizationStatus.memorized => AppColors.srs5,
        MemorizationStatus.needsReview => const Color(0xFF991B1B),
      };
}
