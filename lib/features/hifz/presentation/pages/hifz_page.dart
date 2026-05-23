import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/presentation/pages/surah_reader_page.dart';
import '../../../stats/presentation/pages/stats_page.dart';
import '../../domain/memorization_status.dart';
import '../providers/memorization_provider.dart';
import '../widgets/quran_heatmap.dart';
import 'masked_surah_picker_page.dart';
import 'test_mode_picker_page.dart';

class HifzPage extends ConsumerWidget {
  const HifzPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(memorizationProvider);
    final notifier = ref.read(memorizationProvider.notifier);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    final memorized = notifier.countByStatus(MemorizationStatus.memorized);
    final memorizing = notifier.countByStatus(MemorizationStatus.memorizing);
    final needsReview = notifier.countByStatus(MemorizationStatus.needsReview);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabHifz),
        actions: [
          IconButton(
            tooltip: 'Statistiques',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsPage()),
            ),
          ),
        ],
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          // Versets en cours, groupés par sourate.
          final verseEntries = state.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progression',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _StatRow(
                        label: 'Mémorisés',
                        value: memorized,
                        color: AppColors.srs5,
                        icon: Icons.check_circle,
                      ),
                      const Divider(height: AppSpacing.xxl),
                      _StatRow(
                        label: 'En cours',
                        value: memorizing,
                        color: AppColors.srs2,
                        icon: Icons.school_outlined,
                      ),
                      const Divider(height: AppSpacing.xxl),
                      _StatRow(
                        label: 'À revoir',
                        value: needsReview,
                        color: AppColors.srs1,
                        icon: Icons.refresh,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const QuranHeatmap(),
              const SizedBox(height: AppSpacing.xl),

              // Modes d'entraînement avancés
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.visibility_off_outlined,
                      label: 'Masquage',
                      subtitle: 'Sourate avec mots cachés',
                      color: theme.colorScheme.tertiaryContainer,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MaskedSurahPickerPage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.quiz_outlined,
                      label: 'Test',
                      subtitle: 'QCM premier/dernier mot…',
                      color: theme.colorScheme.secondaryContainer,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TestModePickerPage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (verseEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Aucun verset suivi',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Ouvrez une sourate et marquez un verset comme "En cours" pour commencer',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Versets suivis',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final entry in verseEntries)
                  _TrackedVerseTile(
                    globalIndex: entry.key,
                    status: entry.value,
                    repo: repo,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.onSurface),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _TrackedVerseTile extends StatelessWidget {
  const _TrackedVerseTile({
    required this.globalIndex,
    required this.status,
    required this.repo,
  });

  final int globalIndex;
  final MemorizationStatus status;
  final QuranRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verse = repo.verses[globalIndex - 1];
    final surah = repo.surahByNumber(verse.surahNumber);

    return Card(
      child: ListTile(
        title: Text(
          '${surah.nameEnglish} ${verse.surahNumber}:${verse.ayahInSurah}',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              verse.arabicText,
              style: AppTypography.ayahSmall(theme.colorScheme.onSurface)
                  .copyWith(fontSize: 18, height: 1.8),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SurahReaderPage(surahNumber: verse.surahNumber),
            ),
          );
        },
      ),
    );
  }
}
