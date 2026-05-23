import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../../stats/presentation/providers/activity_log_provider.dart';
import '../../domain/test_mode.dart';

/// Écran de quiz QCM 4 options selon le mode choisi.
///
/// - firstWord : on cache le 1er mot du verset, choix parmi 4 mots
/// - lastWord  : on cache le dernier mot, choix parmi 4 mots
/// - nextVerse : on montre verset N, choix parmi 4 versets (le bon est N+1)
/// - previousVerse : pareil, le bon est N-1
class TestModePage extends ConsumerStatefulWidget {
  const TestModePage({
    super.key,
    required this.mode,
    required this.surahNumber,
    this.totalQuestions = 10,
  });

  final HifzTestMode mode;
  final int surahNumber;
  final int totalQuestions;

  @override
  ConsumerState<TestModePage> createState() => _TestModePageState();
}

class _TestModePageState extends ConsumerState<TestModePage> {
  late final List<_Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_Question> _buildQuestions() {
    final repo = ref.read(quranRepositoryProvider).value;
    if (repo == null) return const [];
    final verses = repo.versesOfSurah(widget.surahNumber);
    if (verses.length < 2) return const [];

    final rng = math.Random();
    final pool = List<Verse>.from(verses);
    pool.shuffle(rng);
    final picks = pool.take(widget.totalQuestions).toList();

    return [for (final v in picks) _makeQuestion(v, verses, rng)];
  }

  _Question _makeQuestion(Verse target, List<Verse> allInSurah, math.Random rng) {
    switch (widget.mode) {
      case HifzTestMode.firstWord:
        return _wordQuestion(target, allInSurah, rng, first: true);
      case HifzTestMode.lastWord:
        return _wordQuestion(target, allInSurah, rng, first: false);
      case HifzTestMode.nextVerse:
        return _adjacentVerseQuestion(target, allInSurah, rng, next: true);
      case HifzTestMode.previousVerse:
        return _adjacentVerseQuestion(target, allInSurah, rng, next: false);
    }
  }

  _Question _wordQuestion(
    Verse target,
    List<Verse> allInSurah,
    math.Random rng, {
    required bool first,
  }) {
    final words = target.arabicText.split(' ');
    final correct = first ? words.first : words.last;
    final displayedText = (first
            ? ['___', ...words.skip(1)]
            : [...words.take(words.length - 1), '___'])
        .join(' ');

    // Distracteurs : 3 mots aléatoires d'autres versets de la sourate
    final candidates = <String>{correct};
    final others = allInSurah.where((v) => v.globalIndex != target.globalIndex).toList()
      ..shuffle(rng);
    for (final v in others) {
      if (candidates.length >= 4) break;
      final ws = v.arabicText.split(' ');
      if (ws.isEmpty) continue;
      candidates.add(first ? ws.first : ws.last);
    }
    final options = candidates.toList()..shuffle(rng);
    final correctIndex = options.indexOf(correct);

    return _Question(
      prompt: displayedText,
      options: options,
      correctIndex: correctIndex,
      reference: '${target.surahNumber}:${target.ayahInSurah}',
    );
  }

  _Question _adjacentVerseQuestion(
    Verse target,
    List<Verse> allInSurah,
    math.Random rng, {
    required bool next,
  }) {
    // On évite premier/dernier verset selon le mode
    Verse picked = target;
    if (next && target.ayahInSurah == allInSurah.length) {
      picked = allInSurah[allInSurah.length - 2];
    }
    if (!next && target.ayahInSurah == 1) {
      picked = allInSurah[1];
    }

    final correctAyah =
        next ? picked.ayahInSurah + 1 : picked.ayahInSurah - 1;
    final correctVerse =
        allInSurah.firstWhere((v) => v.ayahInSurah == correctAyah);

    final candidates = <Verse>{correctVerse};
    final others = allInSurah
        .where((v) =>
            v.globalIndex != picked.globalIndex &&
            v.globalIndex != correctVerse.globalIndex)
        .toList()
      ..shuffle(rng);
    for (final v in others) {
      if (candidates.length >= 4) break;
      candidates.add(v);
    }
    final options = candidates.toList()..shuffle(rng);
    final correctIndex = options.indexOf(correctVerse);

    return _Question(
      prompt: picked.arabicText,
      options: [for (final v in options) v.arabicText],
      correctIndex: correctIndex,
      reference: '${picked.surahNumber}:${picked.ayahInSurah}',
    );
  }

  void _answer(int idx) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      if (idx == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
    ref.read(activityLogProvider.notifier).logActivity();
  }

  void _next() {
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode.label)),
        body: const Center(
          child: Text('Pas assez de versets dans cette sourate pour tester.'),
        ),
      );
    }

    if (_currentIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test terminé')),
        body: _CompletionView(
          score: _score,
          total: _questions.length,
          mode: widget.mode,
        ),
      );
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title:
            Text('${widget.mode.label} ${_currentIndex + 1}/${_questions.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _currentIndex / _questions.length,
                minHeight: 6,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull / 2),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                q.reference,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Prompt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    q.prompt,
                    style:
                        AppTypography.ayahMedium(theme.colorScheme.onSurface),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text(
                widget.mode == HifzTestMode.firstWord ||
                        widget.mode == HifzTestMode.lastWord
                    ? 'Choisissez le mot manquant'
                    : 'Quel est le verset ${widget.mode == HifzTestMode.nextVerse ? "suivant" : "précédent"} ?',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.md),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: q.options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final isCorrect = i == q.correctIndex;
                    final isSelected = i == _selectedAnswer;
                    Color? bg;
                    Color? fg;
                    Widget? trailing;
                    if (_answered) {
                      if (isCorrect) {
                        bg = AppColors.srs5.withValues(alpha: 0.2);
                        fg = AppColors.srs5;
                        trailing = const Icon(Icons.check_circle,
                            color: AppColors.srs5);
                      } else if (isSelected) {
                        bg = AppColors.srs1.withValues(alpha: 0.2);
                        fg = AppColors.srs1;
                        trailing =
                            const Icon(Icons.cancel, color: AppColors.srs1);
                      }
                    }
                    return Material(
                      color: bg ?? theme.colorScheme.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: InkWell(
                        onTap: _answered ? null : () => _answer(i),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    q.options[i],
                                    style: AppTypography.ayahSmall(
                                      fg ?? theme.colorScheme.onSurface,
                                    ).copyWith(fontSize: 20),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                              if (trailing != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                trailing,
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_answered)
                FilledButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _currentIndex + 1 == _questions.length
                        ? 'Voir le résultat'
                        : 'Suivant',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question {
  const _Question({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.reference,
  });
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String reference;
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.score,
    required this.total,
    required this.mode,
  });
  final int score;
  final int total;
  final HifzTestMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0 : score / total;
    final color = ratio >= 0.8
        ? AppColors.srs5
        : ratio >= 0.5
            ? AppColors.srs3
            : AppColors.srs1;
    final emoji =
        ratio >= 0.8 ? '🎉' : ratio >= 0.5 ? '👍' : '💪';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Score : $score / $total',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${(ratio * 100).toStringAsFixed(0)}% de bonnes réponses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              mode.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
