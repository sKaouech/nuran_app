import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/presentation/pages/surah_reader_page.dart';
import '../providers/bookmarks_provider.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarks = ref.watch(bookmarksProvider);
    final asyncRepo = ref.watch(quranRepositoryProvider);
    final locale = ref.watch(localeProvider);
    final translationLang =
        locale.languageCode == 'ar' ? 'fr' : locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Signets')),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          final entries = bookmarks.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_outline,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Aucun signet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tapez sur le ruban à côté d\'un verset pour le sauvegarder',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final verse = repo.verses[entry.key - 1];
              final surah = repo.surahByNumber(verse.surahNumber);
              final translation =
                  repo.translationOf(verse, translationLang);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SurahReaderPage(
                          surahNumber: verse.surahNumber,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${surah.nameEnglish} • ${verse.surahNumber}:${verse.ayahInSurah}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Modifier la note',
                              icon: const Icon(Icons.edit_note),
                              onPressed: () => _editNote(
                                context,
                                ref,
                                entry.key,
                                entry.value,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Supprimer le signet',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(bookmarksProvider.notifier)
                                  .remove(entry.key),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            verse.arabicText,
                            style: AppTypography.ayahSmall(
                              theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (translation != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            translation,
                            style: AppTypography.translation(
                              theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (entry.value.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              entry.value,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    int globalIndex,
    String currentNote,
  ) async {
    final controller = TextEditingController(text: currentNote);
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note personnelle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 280,
          decoration: const InputDecoration(
            hintText: 'Pourquoi ce verset vous marque ?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (note != null) {
      await ref.read(bookmarksProvider.notifier).setNote(globalIndex, note);
    }
  }
}
