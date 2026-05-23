import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../murajaa/presentation/providers/fsrs_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';

/// Grille 30 juz × 1 case montrant la **force du souvenir** par juz.
///
/// La couleur est dérivée de la **stability moyenne FSRS** des cartes du juz :
/// - 0 j (gris) : aucun verset travaillé
/// - 1–7 j : début d'apprentissage
/// - 7–30 j : mémorisé récemment
/// - 30–180 j : bien ancré
/// - &gt; 180 j : très stable (Murajaa à vie)
class QuranHeatmap extends ConsumerWidget {
  const QuranHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cards = ref.watch(fsrsCardsProvider);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return asyncRepo.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (repo) {
        // Pré-calcule par juz : nombre total + somme stability + nb cartes actives.
        final juzStats = <int, _JuzStat>{};
        for (var j = 1; j <= 30; j++) {
          juzStats[j] = const _JuzStat(
            total: 0,
            activeCards: 0,
            stabilitySum: 0,
            stableCount: 0,
          );
        }
        for (final verse in repo.verses) {
          final stat = juzStats[verse.juz]!;
          final card = cards[verse.globalIndex];
          juzStats[verse.juz] = _JuzStat(
            total: stat.total + 1,
            activeCards: stat.activeCards + (card != null ? 1 : 0),
            stabilitySum: stat.stabilitySum + (card?.stability ?? 0),
            stableCount:
                stat.stableCount + ((card?.stability ?? 0) >= 7 ? 1 : 0),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Force du souvenir',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.psychology_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const Spacer(),
                    Text(
                      '30 juz',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Basé sur la stability FSRS de vos cartes',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const columns = 10;
                    const gap = 4.0;
                    final cellSize =
                        (constraints.maxWidth - (columns - 1) * gap) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var j = 1; j <= 30; j++)
                          _JuzCell(
                            juz: j,
                            stat: juzStats[j]!,
                            size: cellSize,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Légende : du moins ancré au plus ancré
                Row(
                  children: [
                    Text(
                      'Fragile',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...[
                      AppColors.srs0,
                      AppColors.srs1,
                      AppColors.srs2,
                      AppColors.srs3,
                      AppColors.srs4,
                      AppColors.srs5,
                    ].map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Ancré',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Stats agrégées par juz pour la heatmap.
class _JuzStat {
  const _JuzStat({
    required this.total,
    required this.activeCards,
    required this.stabilitySum,
    required this.stableCount,
  });
  final int total;
  final int activeCards;
  final double stabilitySum;
  final int stableCount;

  /// Stability moyenne (en jours) sur les cartes actives.
  double get avgStability =>
      activeCards == 0 ? 0 : stabilitySum / activeCards;

  /// Score composite 0-1 : combinaison de couverture et de stabilité.
  /// - couverture = activeCards / total
  /// - intensité = log10(avgStability + 1) / log10(181) (saturé à 180 j)
  /// - score = couverture × intensité
  double get score {
    if (total == 0 || activeCards == 0) return 0;
    final coverage = activeCards / total;
    // Échelle log : 1j → 0.13 ; 7j → 0.40 ; 30j → 0.65 ; 180j → 1.0
    final s = avgStability.clamp(0.0, 180.0);
    final intensity =
        s == 0 ? 0.0 : math.log(s + 1) / math.log(181);
    return (coverage * intensity).clamp(0.0, 1.0);
  }
}

class _JuzCell extends StatelessWidget {
  const _JuzCell({required this.juz, required this.stat, required this.size});

  final int juz;
  final _JuzStat stat;
  final double size;

  Color _color() {
    final s = stat.score;
    if (s == 0) return AppColors.srs0;
    if (s < 0.1) return AppColors.srs1;
    if (s < 0.25) return AppColors.srs2;
    if (s < 0.5) return AppColors.srs3;
    if (s < 0.75) return AppColors.srs4;
    return AppColors.srs5;
  }

  String _stabilityLabel() {
    if (stat.activeCards == 0) return 'non travaillé';
    final s = stat.avgStability;
    if (s < 1) return '&lt; 1 jour';
    if (s < 7) return '${s.toStringAsFixed(1)} j';
    if (s < 30) return '${s.toStringAsFixed(0)} j';
    if (s < 365) return '${(s / 30).toStringAsFixed(1)} mois';
    return '${(s / 365).toStringAsFixed(1)} ans';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message:
          'Juz $juz\n${stat.activeCards}/${stat.total} versets travaillés\nStability moyenne : ${_stabilityLabel()}',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color(),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        child: Text(
          '$juz',
          style: theme.textTheme.labelSmall?.copyWith(
            color: stat.score > 0.5
                ? Colors.white
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
