import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/reading_preferences_provider.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../audio_player/presentation/widgets/verse_audio_menu.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../hifz/presentation/widgets/memorization_button.dart';
import '../../domain/entities/verse.dart';

class AyahCard extends ConsumerWidget {
  const AyahCard({
    super.key,
    required this.verse,
    this.translation,
  });

  final Verse verse;
  final String? translation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioState = ref.watch(audioPlayerProvider);
    final isCurrent = audioState.currentSurah == verse.surahNumber &&
        audioState.currentAyah == verse.ayahInSurah;

    return Card(
      shape: RoundedRectangleBorder(
        side: isCurrent
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onLongPress: () => showVerseAudioMenu(context, verse),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${verse.ayahInSurah}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                MemorizationButton(globalIndex: verse.globalIndex),
                const Spacer(),
                BookmarkButton(globalIndex: verse.globalIndex),
                _PlayButton(verse: verse, isCurrent: isCurrent),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse.arabicText,
                style: AppTypography.ayahMedium(theme.colorScheme.onSurface)
                    .copyWith(
                  fontSize: 24 *
                      ref.watch(readingPreferencesProvider).fontScale,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (translation != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Text(
                translation!,
                style: AppTypography.translation(
                  theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _PlayButton extends ConsumerWidget {
  const _PlayButton({required this.verse, required this.isCurrent});

  final Verse verse;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final controller = ref.read(audioPlayerProvider.notifier);
    final isPlayingThis = isCurrent && audioState.isPlaying;
    final isLoadingThis = isCurrent && audioState.isLoading;

    return IconButton.filledTonal(
      onPressed: () {
        if (isCurrent) {
          controller.togglePlayPause();
        } else {
          controller.playVerse(
            surah: verse.surahNumber,
            ayah: verse.ayahInSurah,
          );
        }
      },
      icon: isLoadingThis
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(isPlayingThis ? Icons.pause : Icons.play_arrow),
    );
  }
}
