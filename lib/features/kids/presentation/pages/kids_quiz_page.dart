import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/haptics.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/surah.dart';
import '../providers/kids_stars_provider.dart';

/// Quiz visuel pour les enfants : associer le nom arabe d'une sourate
/// à son nom français parmi 4 options.
class KidsQuizPage extends ConsumerStatefulWidget {
  const KidsQuizPage({super.key});

  @override
  ConsumerState<KidsQuizPage> createState() => _KidsQuizPageState();
}

class _KidsQuizPageState extends ConsumerState<KidsQuizPage> {
  static const _totalQuestions = 5;

  late final List<_QuizQuestion> _questions;
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_QuizQuestion> _buildQuestions() {
    final repo = ref.read(quranRepositoryProvider).value;
    if (repo == null) return const [];
    // On joue avec le Juz 'Amma (78..114) → 37 sourates
    final juzAmma = repo.surahs.where((s) => s.number >= 78).toList();
    final rng = math.Random();

    final picks = (juzAmma.toList()..shuffle(rng)).take(_totalQuestions).toList();
    return picks.map((target) {
      final distractors = (juzAmma
          .where((s) => s.number != target.number)
          .toList()
        ..shuffle(rng))
          .take(3)
          .toList();
      final options = [target, ...distractors]..shuffle(rng);
      final correctIndex = options.indexOf(target);
      return _QuizQuestion(
        target: target,
        options: options,
        correctIndex: correctIndex,
      );
    }).toList();
  }

  void _onAnswer(int idx) {
    if (_answered) return;
    final isCorrect = idx == _questions[_currentIndex].correctIndex;
    if (isCorrect) {
      Haptics.success();
    } else {
      Haptics.error();
    }
    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      if (isCorrect) {
        _correctCount++;
      }
    });
  }

  Future<void> _next() async {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      return;
    }
    // Fin du quiz : attribuer les étoiles
    final ratio = _correctCount / _questions.length;
    final stars = ratio >= 0.8 ? 3 : (ratio > 0 ? 1 : 0);
    await ref.read(kidsStarsProvider.notifier).award(stars);
    if (!mounted) return;
    await _showCompletion(stars);
  }

  Future<void> _showCompletion(int starsEarned) async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSpacing.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              starsEarned >= 3 ? '🎉' : starsEarned >= 1 ? '👍' : '💪',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Score : $_correctCount / ${_questions.length}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < starsEarned ? Icons.star : Icons.star_border,
                  color: const Color(0xFFB8860B),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              starsEarned > 0
                  ? '+$starsEarned étoile${starsEarned > 1 ? "s" : ""} !'
                  : 'Pas d\'étoile, mais ne lâche rien !',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Chargement…')),
      );
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text('Quiz ${_currentIndex + 1} / ${_questions.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _currentIndex / _questions.length,
                minHeight: 8,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull / 2),
                color: theme.colorScheme.primary,
                backgroundColor:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Comment s\'appelle cette sourate ?',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                ),
                child: Text(
                  q.target.nameArabic,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1B1A),
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(
                child: ListView.separated(
                  itemCount: q.options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final option = q.options[i];
                    final isCorrect = i == q.correctIndex;
                    final isSelected = i == _selectedAnswer;
                    Color? bg;
                    Color? fg;
                    Widget? trailing;
                    if (_answered) {
                      if (isCorrect) {
                        bg = AppColors.srs5.withValues(alpha: 0.25);
                        fg = AppColors.srs5;
                        trailing = const Icon(Icons.check_circle,
                            color: AppColors.srs5);
                      } else if (isSelected) {
                        bg = AppColors.srs1.withValues(alpha: 0.25);
                        fg = AppColors.srs1;
                        trailing =
                            const Icon(Icons.cancel, color: AppColors.srs1);
                      }
                    }
                    return Material(
                      color: bg ?? theme.colorScheme.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        onTap: _answered ? null : () => _onAnswer(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.nameEnglish,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: fg,
                                  ),
                                ),
                              ),
                              ?trailing,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_answered)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      _currentIndex + 1 == _questions.length
                          ? 'Voir le résultat'
                          : 'Suivant',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.target,
    required this.options,
    required this.correctIndex,
  });
  final Surah target;
  final List<Surah> options;
  final int correctIndex;
}
