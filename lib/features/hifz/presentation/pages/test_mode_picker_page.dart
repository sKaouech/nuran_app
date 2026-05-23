import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../domain/test_mode.dart';
import 'test_mode_page.dart';

/// Écran de sélection : choix du mode de test + sourate cible.
class TestModePickerPage extends ConsumerStatefulWidget {
  const TestModePickerPage({super.key});

  @override
  ConsumerState<TestModePickerPage> createState() =>
      _TestModePickerPageState();
}

class _TestModePickerPageState extends ConsumerState<TestModePickerPage> {
  HifzTestMode _mode = HifzTestMode.firstWord;
  int _surahNumber = 78; // Juz 'Amma par défaut

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return asyncRepo.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (repo) {
        return Scaffold(
          appBar: AppBar(title: const Text('Mode Test')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Quel type de test ?',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ...HifzTestMode.values.map((m) {
                final selected = _mode == m;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: InkWell(
                      onTap: () => setState(() => _mode = m),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            Icon(
                              _iconFor(m),
                              color: selected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.label,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: selected
                                          ? theme.colorScheme
                                              .onPrimaryContainer
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: selected
                                          ? theme.colorScheme
                                              .onPrimaryContainer
                                          : theme
                                              .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle,
                                color:
                                    theme.colorScheme.onPrimaryContainer,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.xl),
              Text(
                'Sourate à tester',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: _surahNumber,
                isExpanded: true,
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final s in repo.surahs)
                    DropdownMenuItem(
                      value: s.number,
                      child: Text(
                        '${s.number}. ${s.nameEnglish} (${s.versesCount} versets)',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _surahNumber = v ?? 78),
              ),

              const SizedBox(height: AppSpacing.xxxl),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TestModePage(
                        mode: _mode,
                        surahNumber: _surahNumber,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer le test'),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconFor(HifzTestMode m) => switch (m) {
        HifzTestMode.firstWord => Icons.first_page,
        HifzTestMode.lastWord => Icons.last_page,
        HifzTestMode.nextVerse => Icons.arrow_forward,
        HifzTestMode.previousVerse => Icons.arrow_back,
      };
}
