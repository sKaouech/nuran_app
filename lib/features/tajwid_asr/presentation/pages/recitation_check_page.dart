import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../murajaa/domain/fsrs_card.dart';
import '../../../murajaa/presentation/providers/fsrs_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../../stats/presentation/providers/activity_log_provider.dart';
import '../../domain/recitation_match.dart';
import '../providers/asr_provider.dart';

/// Page de vérification de récitation pour un verset donné.
/// L'utilisateur tape "Récitez" → parle → l'app compare la transcription au
/// texte attendu et affiche un score + diff mot-à-mot.
class RecitationCheckPage extends ConsumerStatefulWidget {
  const RecitationCheckPage({super.key, required this.verse});

  final Verse verse;

  @override
  ConsumerState<RecitationCheckPage> createState() =>
      _RecitationCheckPageState();
}

class _RecitationCheckPageState extends ConsumerState<RecitationCheckPage> {
  RecitationResult? _result;
  bool _initializing = true;
  bool _asrAvailable = false;

  /// On garde une référence locale au controller pour pouvoir appeler `cancel`
  /// depuis `dispose` sans passer par `ref` (qui est déjà disposed à ce stade).
  AsrController? _asrController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _asrController = ref.read(asrControllerProvider.notifier);
      final ok = await _asrController!.initialize();
      if (mounted) {
        setState(() {
          _initializing = false;
          _asrAvailable = ok;
        });
      }
    });
  }

  @override
  void dispose() {
    // Différer la mutation du state notifier APRÈS le dispose, sinon elle
    // déclencherait markNeedsBuild sur des widgets en cours de destruction.
    final controller = _asrController;
    if (controller != null) {
      Future.microtask(controller.cancel);
    }
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() => _result = null);
    await ref.read(asrControllerProvider.notifier).startListening();
  }

  Future<void> _stopAndAnalyze() async {
    final asr = ref.read(asrControllerProvider);
    await ref.read(asrControllerProvider.notifier).stopListening();
    final recognized = asr.recognizedText;
    final result = ArabicTextMatcher.compare(
      expected: widget.verse.arabicText,
      recognized: recognized,
    );
    setState(() => _result = result);

    // Log activité + notation FSRS automatique selon le score
    ref.read(activityLogProvider.notifier).logActivity();
    final rating = _ratingFromScore(result.scorePercent);
    await ref
        .read(fsrsCardsProvider.notifier)
        .rate(widget.verse.globalIndex, rating);
  }

  FsrsRating _ratingFromScore(int score) {
    if (score >= 95) return FsrsRating.easy;
    if (score >= 80) return FsrsRating.good;
    if (score >= 50) return FsrsRating.hard;
    return FsrsRating.again;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asr = ref.watch(asrControllerProvider);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return asyncRepo.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (repo) {
        final surah = repo.surahByNumber(widget.verse.surahNumber);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  'Vérifier ma récitation',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${surah.nameEnglish} • ${widget.verse.surahNumber}:${widget.verse.ayahInSurah}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _initializing
                  ? const Center(child: CircularProgressIndicator())
                  : !_asrAvailable
                      ? _UnavailableView(theme: theme)
                      : Column(
                          children: [
                            // Verset attendu (avec coloration si résultat dispo)
                            Expanded(
                              child: SingleChildScrollView(
                                child: _result == null
                                    ? _ExpectedText(verse: widget.verse)
                                    : _AnnotatedText(result: _result!),
                              ),
                            ),

                            // Zone de transcription en cours
                            if (asr.isListening || asr.recognizedText.isNotEmpty)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (asr.isListening) ...[
                                          Icon(
                                            Icons.mic,
                                            size: 16,
                                            color: AppColors.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Écoute en cours…',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ] else
                                          Text(
                                            'Reconnu',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        asr.recognizedText.isEmpty
                                            ? '…'
                                            : asr.recognizedText,
                                        style: AppTypography.ayahSmall(
                                          theme.colorScheme.onSurface,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Score si résultat dispo
                            if (_result != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _ScoreCard(result: _result!),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // Bouton principal
                            SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: FilledButton.icon(
                                onPressed: asr.isListening
                                    ? _stopAndAnalyze
                                    : _startListening,
                                style: FilledButton.styleFrom(
                                  backgroundColor: asr.isListening
                                      ? AppColors.error
                                      : null,
                                ),
                                icon: Icon(
                                  asr.isListening
                                      ? Icons.stop
                                      : Icons.mic,
                                ),
                                label: Text(
                                  asr.isListening
                                      ? 'Arrêter et analyser'
                                      : _result == null
                                          ? 'Récitez le verset'
                                          : 'Réessayer',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        );
      },
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reconnaissance vocale indisponible',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Vérifiez que vous avez autorisé Nuran à utiliser le microphone et que l\'arabe est installé dans vos langues système.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectedText extends StatelessWidget {
  const _ExpectedText({required this.verse});
  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          verse.arabicText,
          style: AppTypography.ayahLarge(theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AnnotatedText extends StatelessWidget {
  const _AnnotatedText({required this.result});
  final RecitationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          spacing: 6,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final m in result.matches)
              _AnnotatedWord(match: m),
          ],
        ),
      ),
    );
  }
}

class _AnnotatedWord extends StatelessWidget {
  const _AnnotatedWord({required this.match});
  final WordMatch match;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (match.status) {
      WordMatchStatus.correct => (
        AppColors.srs5.withValues(alpha: 0.18),
        AppColors.srs5,
      ),
      WordMatchStatus.wrong => (
        AppColors.warning.withValues(alpha: 0.2),
        AppColors.warning,
      ),
      WordMatchStatus.missing => (
        AppColors.error.withValues(alpha: 0.18),
        AppColors.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        match.expected,
        style: AppTypography.ayahMedium(fg),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});
  final RecitationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = result.scorePercent;
    final color = score >= 80
        ? AppColors.srs5
        : score >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$score',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.gradeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${result.correctCount} / ${result.matches.length} mots corrects',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Carte FSRS mise à jour automatiquement',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
