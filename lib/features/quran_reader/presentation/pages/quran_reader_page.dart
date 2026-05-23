import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../bookmarks/presentation/pages/bookmarks_page.dart';
import '../../data/quran_repository.dart';
import 'mushaf_page.dart';
import 'search_page.dart';
import 'surah_reader_page.dart';

class QuranReaderPage extends ConsumerWidget {
  const QuranReaderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabRead),
        actions: [
          IconButton(
            tooltip: 'Mode mushaf',
            icon: const Icon(Icons.auto_stories_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MushafPage(initialPage: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Rechercher',
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Signets',
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarksPage()),
              );
            },
          ),
        ],
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (repo) => ListView.builder(
          itemCount: repo.surahs.length,
          itemBuilder: (context, index) {
            final surah = repo.surahs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '${surah.number}',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                ),
              ),
              title: Text(
                surah.nameEnglish,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                '${surah.nameEnglishTranslation} • ${surah.versesCount} versets • ${surah.isMeccan ? "Mecque" : "Médine"}',
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  surah.nameArabic,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Amiri',
                      ),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SurahReaderPage(surahNumber: surah.number),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
