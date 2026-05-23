import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/reading_preferences_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';

/// Mode "Masquage progressif" sur une sourate entière.
///
/// L'utilisateur ajuste un slider global de masquage (0–100%), et tous les
/// versets de la sourate cachent une part proportionnelle de leurs mots.
/// Idéal pour s'entraîner à réciter une sourate qu'on a déjà mémorisée.
class MaskedSurahPage extends ConsumerStatefulWidget {
  const MaskedSurahPage({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  ConsumerState<MaskedSurahPage> createState() => _MaskedSurahPageState();
}

class _MaskedSurahPageState extends ConsumerState<MaskedSurahPage> {
  double _maskPercent = 50;
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);
    final translationLang =
        ref.watch(readingPreferencesProvider).translationLang;

    return asyncRepo.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (repo) {
        final surah = repo.surahByNumber(widget.surahNumber);
        final verses = repo.versesOfSurah(widget.surahNumber);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  'Masquage',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${surah.nameEnglish} • ${verses.length} versets',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _showTranslation
                    ? 'Cacher traduction'
                    : 'Montrer traduction',
                icon: Icon(
                  _showTranslation
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _showTranslation = !_showTranslation),
              ),
            ],
          ),
          body: Column(
            children: [
              // Slider global de masquage
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 20),
                    Expanded(
                      child: Slider(
                        value: _maskPercent,
                        max: 100,
                        divisions: 4,
                        label: '${_maskPercent.toInt()}%',
                        onChanged: (v) =>
                            setState(() => _maskPercent = v),
                      ),
                    ),
                    const Icon(Icons.visibility_off_outlined, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${_maskPercent.toInt()}%',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: verses.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    final translation = _showTranslation
                        ? repo.translationOf(verse, translationLang)
                        : null;
                    return _MaskedVerseCard(
                      verse: verse,
                      maskPercent: _maskPercent,
                      translation: translation,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MaskedVerseCard extends StatelessWidget {
  const _MaskedVerseCard({
    required this.verse,
    required this.maskPercent,
    this.translation,
  });

  final Verse verse;
  final double maskPercent;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = verse.arabicText.split(' ');
    final maskCount = (words.length * maskPercent / 100).round();
    final maskFromIndex = words.length - maskCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${verse.ayahInSurah}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Juz ${verse.juz}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 6,
                runSpacing: 10,
                alignment: WrapAlignment.start,
                children: [
                  for (var i = 0; i < words.length; i++)
                    if (i < maskFromIndex)
                      Text(
                        words[i],
                        style: AppTypography.ayahMedium(
                          theme.colorScheme.onSurface,
                        ),
                      )
                    else
                      _MaskedWord(word: words[i]),
                ],
              ),
            ),
            if (translation != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Text(
                translation!,
                style: AppTypography.translation(
                  theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mot masqué : un tap révèle temporairement le mot.
class _MaskedWord extends StatefulWidget {
  const _MaskedWord({required this.word});
  final String word;

  @override
  State<_MaskedWord> createState() => _MaskedWordState();
}

class _MaskedWordState extends State<_MaskedWord> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_revealed) {
      return GestureDetector(
        onTap: () => setState(() => _revealed = false),
        child: Text(
          widget.word,
          style: AppTypography.ayahMedium(
            theme.colorScheme.primary,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          '•' * widget.word.length.clamp(2, 6),
          style: AppTypography.ayahMedium(
            theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
