import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/audio_player_provider.dart';

/// Mini-player flottant affiché en bas quand un verset est en cours d'écoute.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);
    if (!state.hasActiveVerse) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final controller = ref.read(audioPlayerProvider.notifier);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ProgressBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    '${state.currentSurah}:${state.currentAyah}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? state.reciter.nameArabic
                            : state.reciter.nameEnglish,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          _ControlChip(
                            label: '${_formatSpeed(state.speed)}x',
                            onTap: controller.cycleSpeed,
                            isHighlighted: state.speed != 1.0,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _ControlChip(
                            label: state.repeatCount == 1
                                ? '×1'
                                : '${state.currentRepeat + 1}/${state.repeatCount}',
                            onTap: controller.cycleRepeatCount,
                            isHighlighted: state.repeatCount > 1,
                            icon: Icons.repeat,
                          ),
                          if (state.rangeStart != null &&
                              state.rangeEnd != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _ControlChip(
                              label:
                                  '${state.rangeStart}–${state.rangeEnd}',
                              onTap: () {},
                              isHighlighted: true,
                              icon: Icons.linear_scale,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: controller.togglePlayPause,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: controller.stop,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formate la vitesse sans .0 superflu (1.0 → "1", 1.5 → "1.5").
  String _formatSpeed(double s) {
    if (s == s.roundToDouble()) return s.toInt().toString();
    return s.toString();
  }
}

/// Chip tappable pour les contrôles rapides (vitesse, répétitions).
class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.isHighlighted = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isHighlighted
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final fgColor = isHighlighted
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: fgColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre de progression fine en haut du mini-player, scrubbable.
class _ProgressBar extends ConsumerWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(audioPlayerProvider.notifier);
    final theme = Theme.of(context);

    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      builder: (context, posSnap) {
        return StreamBuilder<Duration?>(
          stream: controller.durationStream,
          builder: (context, durSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = durSnap.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds.toDouble();
            final currentMs = position.inMilliseconds
                .clamp(0, duration.inMilliseconds)
                .toDouble();

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 12,
                ),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                thumbColor: theme.colorScheme.primary,
                overlayColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: maxMs > 0 ? currentMs : 0,
                max: maxMs > 0 ? maxMs : 1,
                onChanged: maxMs > 0
                    ? (v) => controller.seek(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
