import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/reading_preferences_provider.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../../stats/presentation/providers/activity_log_provider.dart';
import '../../domain/fsrs_card.dart';
import '../providers/fsrs_provider.dart';

/// Session de révision FSRS : carrousel verset par verset avec 4 boutons
/// (Again / Hard / Good / Easy) qui notent et programment la prochaine échéance.
class FsrsSessionPage extends ConsumerStatefulWidget {
  const FsrsSessionPage({super.key});

  @override
  ConsumerState<FsrsSessionPage> createState() => _FsrsSessionPageState();
}

class _FsrsSessionPageState extends ConsumerState<FsrsSessionPage> {
  late final List<Verse> _initialQueue;
  int _currentIndex = 0;
  int _again = 0;
  int _hard = 0;
  int _good = 0;
  int _easy = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _initialQueue = List<Verse>.from(ref.read(murajaaQueueProvider));
  }

  AudioPlayerController? _audioController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioController ??= ref.read(audioPlayerProvider.notifier);
  }

  @override
  void dispose() {
    // Différer la mutation du state notifier APRÈS le dispose, sinon elle
    // déclencherait markNeedsBuild sur des widgets en cours de destruction.
    final controller = _audioController;
    if (controller != null) {
      Future.microtask(controller.stop);
    }
    super.dispose();
  }

  Future<void> _rate(FsrsRating rating) async {
    final verse = _initialQueue[_currentIndex];
    await ref
        .read(fsrsCardsProvider.notifier)
        .rate(verse.globalIndex, rating);
    ref.read(activityLogProvider.notifier).logActivity();

    setState(() {
      switch (rating) {
        case FsrsRating.again:
          _again++;
          break;
        case FsrsRating.hard:
          _hard++;
          break;
        case FsrsRating.good:
          _good++;
          break;
        case FsrsRating.easy:
          _easy++;
          break;
      }
      _currentIndex++;
      _revealed = false;
    });

    ref.read(audioPlayerProvider.notifier).stop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_initialQueue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Murajaa')),
        body: _EmptyState(theme: theme),
      );
    }

    if (_currentIndex >= _initialQueue.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session terminée')),
        body: _CompletionView(
          total: _initialQueue.length,
          again: _again,
          hard: _hard,
          good: _good,
          easy: _easy,
        ),
      );
    }

    final verse = _initialQueue[_currentIndex];
    final card = ref.read(fsrsCardsProvider.notifier).cardFor(verse.globalIndex);
    final algo = ref.read(fsrsCardsProvider.notifier).algorithm;
    final intervals = algo.previewIntervals(card, DateTime.now());
    final asyncRepo = ref.watch(quranRepositoryProvider);
    final translationLang =
        ref.watch(readingPreferencesProvider).translationLang;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Murajaa ${_currentIndex + 1} / ${_initialQueue.length}',
        ),
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
                  LinearProgressIndicator(
                    value: _currentIndex / _initialQueue.length,
                    minHeight: 6,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull / 2),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${surah.nameEnglish} • ${verse.surahNumber}:${verse.ayahInSurah}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      _RetrievabilityBadge(card: card),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

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
                            if (translation != null &&
                                _revealed) ...[
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

                  // Bouton "Écouter" + "Montrer traduction"
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(audioPlayerProvider.notifier)
                            .playVerse(
                              surah: verse.surahNumber,
                              ayah: verse.ayahInSurah,
                            ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Écouter'),
                      ),
                      if (translation != null)
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _revealed = !_revealed),
                          icon: Icon(
                            _revealed
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          label: Text(
                            _revealed
                                ? 'Cacher traduction'
                                : 'Montrer traduction',
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Comment as-tu retenu ce verset ?',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4 boutons FSRS
                  Row(
                    children: [
                      Expanded(
                        child: _RatingButton(
                          label: 'Again',
                          subtitle: _formatInterval(intervals[FsrsRating.again]),
                          color: AppColors.srs1,
                          onTap: () => _rate(FsrsRating.again),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _RatingButton(
                          label: 'Hard',
                          subtitle: _formatInterval(intervals[FsrsRating.hard]),
                          color: AppColors.warning,
                          onTap: () => _rate(FsrsRating.hard),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _RatingButton(
                          label: 'Good',
                          subtitle: _formatInterval(intervals[FsrsRating.good]),
                          color: AppColors.srs4,
                          onTap: () => _rate(FsrsRating.good),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _RatingButton(
                          label: 'Easy',
                          subtitle: _formatInterval(intervals[FsrsRating.easy]),
                          color: AppColors.srs5,
                          onTap: () => _rate(FsrsRating.easy),
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

  /// Format humain d'un intervalle en jours.
  /// 0.001 = "1 min", 0.5 = "12 h", 1 = "1 j", 30 = "1 mo", 365 = "1 an"
  String _formatInterval(double? days) {
    if (days == null) return '—';
    if (days < 1 / 24) {
      final mins = (days * 1440).round();
      return '${mins}m';
    }
    if (days < 1) {
      final hours = (days * 24).round();
      return '${hours}h';
    }
    if (days < 30) {
      return '${days.round()}j';
    }
    if (days < 365) {
      return '${(days / 30).round()}mo';
    }
    return '${(days / 365).toStringAsFixed(1)}an';
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetrievabilityBadge extends StatelessWidget {
  const _RetrievabilityBadge({required this.card});
  final FsrsCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (card.lastReviewAt == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          'Nouvelle',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final r = card.retrievabilityAt(DateTime.now());
    final color = r > 0.7
        ? AppColors.srs5
        : r > 0.4
            ? AppColors.warning
            : AppColors.srs1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'R ${(r * 100).toStringAsFixed(0)}%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
              'Aucune révision en attente',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Revenez plus tard ou marquez de nouveaux versets comme mémorisés.',
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
    required this.total,
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  final int total;
  final int again;
  final int hard;
  final int good;
  final int easy;

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
              'Session FSRS terminée',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            _Row(label: 'Versets révisés', value: '$total'),
            const SizedBox(height: AppSpacing.sm),
            _Row(label: 'Again', value: '$again', color: AppColors.srs1),
            _Row(label: 'Hard', value: '$hard', color: AppColors.warning),
            _Row(label: 'Good', value: '$good', color: AppColors.srs4),
            _Row(label: 'Easy', value: '$easy', color: AppColors.srs5),
            const SizedBox(height: AppSpacing.xxxl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
