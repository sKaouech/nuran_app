import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../quran_reader/data/quran_repository.dart';
import 'masked_surah_page.dart';

/// Sélecteur de sourate pour le mode masquage.
class MaskedSurahPickerPage extends ConsumerWidget {
  const MaskedSurahPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Masquage — Choisir sourate')),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) => ListView.builder(
          itemCount: repo.surahs.length,
          itemBuilder: (context, index) {
            final surah = repo.surahs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${surah.number}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(surah.nameEnglish),
              subtitle: Text(
                '${surah.nameEnglishTranslation} • ${surah.versesCount} versets',
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  surah.nameArabic,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MaskedSurahPage(surahNumber: surah.number),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
