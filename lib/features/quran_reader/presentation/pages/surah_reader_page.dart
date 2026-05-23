import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/reading_preferences_provider.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../data/quran_repository.dart';
import '../widgets/ayah_card.dart';

class SurahReaderPage extends ConsumerWidget {
  const SurahReaderPage({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRepo = ref.watch(quranRepositoryProvider);
    final translationLang = ref.watch(readingPreferencesProvider).translationLang;

    return asyncRepo.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (repo) {
        final surah = repo.surahByNumber(surahNumber);
        final verses = repo.versesOfSurah(surahNumber);
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(surah.nameEnglish, style: theme.textTheme.titleMedium),
                Text(
                  '${surah.nameEnglishTranslation} • ${verses.length} ${verses.length > 1 ? "versets" : "verset"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Lire toute la sourate',
                onPressed: () {
                  ref.read(audioPlayerProvider.notifier).playRange(
                        surah: surahNumber,
                        fromAyah: 1,
                        toAyah: verses.length,
                      );
                },
                icon: const Icon(Icons.playlist_play),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            itemCount: verses.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Bismillah ou en-tête sourate
                return _SurahHeader(surahName: surah.nameArabic);
              }
              final verse = verses[index - 1];
              final translation = repo.translationOf(verse, translationLang);
              return AyahCard(
                verse: verse,
                translation: translation,
              );
            },
          ),
        );
      },
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surahName});

  final String surahName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          ),
          child: Text(
            surahName,
            style: AppTypography.ayahMedium(
              theme.colorScheme.onSurface,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          style: AppTypography.ayahLarge(
            theme.colorScheme.onSurface,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
