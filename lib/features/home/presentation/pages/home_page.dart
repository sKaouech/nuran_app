import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../../shared/widgets/fade_in_on_appear.dart';
import '../../../hifz/domain/memorization_status.dart';
import '../../../hifz/presentation/pages/create_plan_page.dart';
import '../../../hifz/presentation/pages/listen_repeat_page.dart';
import '../../../hifz/presentation/pages/review_session_page.dart';
import '../../../hifz/presentation/providers/hifz_plan_provider.dart';
import '../../../hifz/presentation/providers/memorization_provider.dart';
import '../../../stats/presentation/providers/activity_log_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/presentation/pages/mushaf_page.dart';
import '../widgets/plan_card.dart';
import '../widgets/quick_action_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final plan = ref.watch(hifzPlanProvider);
    ref.watch(memorizationProvider); // pour rebuild auto sur changement
    final memoNotifier = ref.read(memorizationProvider.notifier);
    final todayVerses = ref.watch(todayPlanVersesProvider);
    final completion = ref.watch(estimatedCompletionProvider);
    final memorized = memoNotifier.countByStatus(MemorizationStatus.memorized);
    final inReview = memoNotifier.countByStatus(MemorizationStatus.needsReview);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          children: [
            Text(
              l10n.greetingMorning,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.todayPlan,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xl),

            if (plan == null)
              FadeInOnAppear(
                child: _EmptyPlanCard(
                  onCreate: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreatePlanPage()),
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (_) {
                  ref.watch(activityLogProvider); // pour rebuild
                  final streak = ref
                      .read(activityLogProvider.notifier)
                      .currentStreak();
                  return PlanCard(
                    versesToMemorize: todayVerses.length,
                    versesToReview: inReview,
                    streakDays: streak,
                    onEdit: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreatePlanPage(),
                      ),
                    ),
                    onDelete: () => _confirmDeletePlan(context, ref),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (completion != null)
                _CompletionBanner(
                  completion: completion,
                  memorized: memorized,
                  locale: locale,
                ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Versets du jour (extrait)
            if (todayVerses.isNotEmpty) ...[
              Text(
                'Versets du jour',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ...todayVerses.take(3).map(
                    (v) => _TodayVerseTile(verseIndex: v.globalIndex),
                  ),
              if (todayVerses.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '+ ${todayVerses.length - 3} autres',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Quick actions (toujours visibles)
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.school_outlined,
                    label: l10n.continueMemorizing,
                    color: theme.colorScheme.primaryContainer,
                    onTap: todayVerses.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ListenRepeatPage(
                                  verse: todayVerses.first,
                                ),
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.refresh,
                    label: l10n.startReview,
                    color: theme.colorScheme.secondaryContainer,
                    onTap: inReview == 0
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReviewSessionPage(),
                              ),
                            ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            QuickActionCard(
              icon: Icons.menu_book_outlined,
              label: l10n.openMushaf,
              color: theme.colorScheme.tertiaryContainer,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MushafPage(initialPage: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePlan(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le plan ?'),
        content: const Text(
          'Cette action supprimera votre plan actuel. Vos statuts de versets '
          'mémorisés seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(hifzPlanProvider.notifier).clear();
    }
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.emptyStatePlanTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.emptyStatePlanDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.emptyStatePlanCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({
    required this.completion,
    required this.memorized,
    required this.locale,
  });

  final DateTime completion;
  final int memorized;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat.yMMMd(locale.languageCode).format(completion);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: 'Hifz complet estimé : ',
                  ),
                  TextSpan(
                    text: dateStr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  TextSpan(
                    text: '\n$memorized versets mémorisés à ce jour',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayVerseTile extends ConsumerWidget {
  const _TodayVerseTile({required this.verseIndex});
  final int verseIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(quranRepositoryProvider).value;
    if (repo == null) return const SizedBox.shrink();
    final verse = repo.verses[verseIndex - 1];
    final surah = repo.surahByNumber(verse.surahNumber);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListenRepeatPage(verse: verse),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${verse.surahNumber}:${verse.ayahInSurah}',
                  style: theme.textTheme.labelSmall?.copyWith(
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
                      surah.nameEnglish,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        verse.arabicText,
                        style: AppTypography.ayahSmall(
                          theme.colorScheme.onSurface,
                        ).copyWith(fontSize: 18, height: 1.6),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_outline,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
