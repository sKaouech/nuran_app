import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/reading_preferences_provider.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../stats/presentation/providers/activity_log_provider.dart';
import '../../domain/memorization_status.dart';
import '../providers/memorization_provider.dart';
import '../providers/review_queue_provider.dart';

/// Carrousel de révision : un verset à la fois, audio, puis boutons d'évaluation.
class ReviewSessionPage extends ConsumerStatefulWidget {
  const ReviewSessionPage({super.key});

  @override
  ConsumerState<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends ConsumerState<ReviewSessionPage> {
  int _currentIndex = 0;
  int _reviewedCount = 0;
  int _markedMemorized = 0;

  AudioPlayerController? _audioController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioController ??= ref.read(audioPlayerProvider.notifier);
  }

  @override
  void dispose() {
    _audioController?.stop();
    super.dispose();
  }

  void _next(MemorizationStatus newStatus) {
    final queue = ref.read(reviewQueueProvider);
    if (_currentIndex >= queue.length) return;

    final verse = queue[_currentIndex];
    ref.read(memorizationProvider.notifier).setStatus(
          verse.globalIndex,
          newStatus,
        );
    ref.read(activityLogProvider.notifier).logActivity();

    setState(() {
      _reviewedCount++;
      if (newStatus == MemorizationStatus.memorized) {
        _markedMemorized++;
      }
      _currentIndex++;
    });

    ref.read(audioPlayerProvider.notifier).stop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // On lit la file initiale au build, mais on garde notre propre index pour
    // ne pas se faire shifter par les mises à jour (les versets changent de
    // statut au fur et à mesure de la session).
    final initialQueue = ref.read(reviewQueueProvider);
    final asyncRepo = ref.watch(quranRepositoryProvider);
    final translationLang = ref.watch(readingPreferencesProvider).translationLang;

    if (initialQueue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Révision')),
        body: const _EmptyState(),
      );
    }

    if (_currentIndex >= initialQueue.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Révision terminée')),
        body: _CompletionView(
          reviewedCount: _reviewedCount,
          markedMemorized: _markedMemorized,
        ),
      );
    }

    final verse = initialQueue[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Révision ${_currentIndex + 1} / ${initialQueue.length}'),
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          final surah = repo.surahByNumber(verse.surahNumber);
          final translation = repo.translationOf(verse, translationLang);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  // Progression
                  LinearProgressIndicator(
                    value: (_currentIndex) / initialQueue.length,
                    minHeight: 6,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull / 2),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    '${surah.nameEnglish} • ${verse.surahNumber}:${verse.ayahInSurah}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                verse.arabicText,
                                style: AppTypography.ayahLarge(
                                  theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (translation != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                translation,
                                style: AppTypography.translation(
                                  theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bouton "Écouter"
                  FilledButton.tonalIcon(
                    onPressed: () {
                      ref.read(audioPlayerProvider.notifier).playVerse(
                            surah: verse.surahNumber,
                            ayah: verse.ayahInSurah,
                          );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Écouter'),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Comment as-tu réussi ?',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Boutons d'évaluation
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _next(MemorizationStatus.needsReview),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Encore'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _next(MemorizationStatus.memorized),
                          icon: const Icon(Icons.check),
                          label: const Text('Mémorisé'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.srs5,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Rien à réviser pour l\'instant',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Marquez un verset comme "À revoir" pour le retrouver ici.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.reviewedCount,
    required this.markedMemorized,
  });

  final int reviewedCount;
  final int markedMemorized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Bravo, session terminée !',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$reviewedCount versets révisés\n$markedMemorized marqués comme mémorisés',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
