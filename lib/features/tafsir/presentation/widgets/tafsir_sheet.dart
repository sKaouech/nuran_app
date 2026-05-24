import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../data/tafsir_repository.dart';
import '../../domain/tafsir_source.dart';

/// Affiche le tafsir d'un verset dans une modal bottom sheet.
Future<void> showTafsirSheet(BuildContext context, Verse verse) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TafsirSheet(verse: verse),
  );
}

class _TafsirSheet extends ConsumerStatefulWidget {
  const _TafsirSheet({required this.verse});
  final Verse verse;

  @override
  ConsumerState<_TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends ConsumerState<_TafsirSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedTafsirProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Tafsir — ${widget.verse.surahNumber}:${widget.verse.ayahInSurah}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Chips pour basculer entre les sources de tafsir
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TafsirSource.values.map((src) {
                    final isSelected = src == selected;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(src.title),
                            Text(
                              src.language,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(selectedTafsirProvider.notifier).state = src;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    widget.verse.arabicText,
                    style: AppTypography.ayahSmall(theme.colorScheme.onSurface)
                        .copyWith(fontSize: 18),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<String?>(
                  future: ref.watch(tafsirRepositoryProvider).tafsirFor(
                        source: selected,
                        globalIndex: widget.verse.globalIndex,
                      ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final text = snapshot.data ?? '—';
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.xxxl,
                      ),
                      child: Directionality(
                        textDirection: selected.isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: Text(
                          text,
                          style: selected.isArabic
                              ? AppTypography.ayahSmall(
                                  theme.colorScheme.onSurface,
                                ).copyWith(fontSize: 17, height: 1.9)
                              : theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                ),
                          textAlign: selected.isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                        ),
                      ),
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
