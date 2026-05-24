import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../murajaa/domain/fsrs_card.dart';
import '../../../murajaa/presentation/providers/fsrs_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../../stats/presentation/providers/activity_log_provider.dart';
import '../../domain/memorization_status.dart';
import '../providers/memorization_provider.dart';

/// Mode "Écoute &amp; Répète" : un verset en boucle audio, texte masqué
/// progressivement pour forcer la mémorisation.
class ListenRepeatPage extends ConsumerStatefulWidget {
  const ListenRepeatPage({super.key, required this.verse});

  final Verse verse;

  @override
  ConsumerState<ListenRepeatPage> createState() => _ListenRepeatPageState();
}

class _ListenRepeatPageState extends ConsumerState<ListenRepeatPage> {
  /// Pourcentage du texte masqué (0 = tout visible, 100 = tout masqué).
  double _maskPercent = 0;

  AudioPlayerController? _audioController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(audioPlayerProvider.notifier);
      _audioController = controller;
      controller
        ..setRepeatCount(10)
        ..playVerse(
          surah: widget.verse.surahNumber,
          ayah: widget.verse.ayahInSurah,
        );
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);
    final locale = ref.watch(localeProvider);
    final translationLang =
        locale.languageCode == 'ar' ? 'fr' : locale.languageCode;
    final audioState = ref.watch(audioPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écoute &amp; Répète'),
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          final translation = repo.translationOf(widget.verse, translationLang);
          final surah = repo.surahByNumber(widget.verse.surahNumber);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Text(
                    '${surah.nameEnglish} • ${widget.verse.surahNumber}:${widget.verse.ayahInSurah}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Texte arabe avec masquage
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: _MaskedAyah(
                          arabicText: widget.verse.arabicText,
                          maskPercent: _maskPercent,
                          theme: theme,
                        ),
                      ),
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

                  const SizedBox(height: AppSpacing.xl),

                  // Slider de masquage
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 20),
                      Expanded(
                        child: Slider(
                          value: _maskPercent,
                          max: 100,
                          divisions: 4,
                          label: '${_maskPercent.toInt()}%',
                          onChanged: (v) => setState(() => _maskPercent = v),
                        ),
                      ),
                      const Icon(Icons.visibility_off_outlined, size: 20),
                    ],
                  ),
                  Text(
                    'Masquer ${_maskPercent.toInt()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Compteur de répétitions
                  if (audioState.repeatCount > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Text(
                        'Répétition ${audioState.currentRepeat + 1} / ${audioState.repeatCount}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),

                  // Boutons d'évaluation
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(memorizationProvider.notifier).setStatus(
                                  widget.verse.globalIndex,
                                  MemorizationStatus.needsReview,
                                );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Encore'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            ref.read(memorizationProvider.notifier).setStatus(
                                  widget.verse.globalIndex,
                                  MemorizationStatus.memorized,
                                );
                            // Première inscription dans FSRS avec note Good
                            ref.read(fsrsCardsProvider.notifier).rate(
                                  widget.verse.globalIndex,
                                  FsrsRating.good,
                                );
                            ref.read(activityLogProvider.notifier)
                                .logActivity();
                            Navigator.of(context).pop();
                          },
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

/// Affiche un texte arabe avec un pourcentage de mots masqués (cachés derrière
/// un bandeau gris). Les mots masqués sont choisis aléatoirement-stable
/// (déterministe par maskPercent pour ne pas changer à chaque rebuild).
class _MaskedAyah extends StatelessWidget {
  const _MaskedAyah({
    required this.arabicText,
    required this.maskPercent,
    required this.theme,
  });

  final String arabicText;
  final double maskPercent;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final words = arabicText.split(' ');
    final maskCount = (words.length * maskPercent / 100).round();
    // Masque les N derniers mots (déterministe, prévisible).
    final maskFromIndex = words.length - maskCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 12,
        children: [
          for (var i = 0; i < words.length; i++)
            if (i < maskFromIndex)
              Text(
                words[i],
                style: AppTypography.ayahLarge(theme.colorScheme.onSurface),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '•' * (words[i].length.clamp(2, 6)),
                  style: AppTypography.ayahLarge(
                    theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
