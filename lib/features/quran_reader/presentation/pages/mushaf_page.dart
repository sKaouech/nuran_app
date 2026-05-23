import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../audio_player/presentation/widgets/verse_audio_menu.dart';
import '../../data/quran_repository.dart';
import '../../domain/entities/verse.dart';

const _totalMushafPages = 604;

/// Mode mushaf : affichage page-par-page (604 pages Madinah) avec swipe RTL.
class MushafPage extends ConsumerStatefulWidget {
  const MushafPage({super.key, this.initialPage = 1});

  final int initialPage;

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Page $_currentPage / $_totalMushafPages'),
        actions: [
          IconButton(
            tooltip: 'Aller à la page',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => _showPagePicker(context),
          ),
        ],
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        // Directionality RTL : avec PageView normal, le swipe gauche → page
        // suivante (comme tourner une page d'un vrai mushaf).
        data: (repo) => Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            controller: _controller,
            itemCount: _totalMushafPages,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              final verses = repo.versesOfPage(pageNumber);
              return _MushafPageView(pageNumber: pageNumber, verses: verses);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showPagePicker(BuildContext context) async {
    final controller = TextEditingController(text: '$_currentPage');
    final input = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aller à la page'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1 — 604',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text);
              if (n != null && n >= 1 && n <= _totalMushafPages) {
                Navigator.of(ctx).pop(n);
              }
            },
            child: const Text('Aller'),
          ),
        ],
      ),
    );
    if (input != null) {
      _controller.jumpToPage(input - 1);
    }
  }
}

class _MushafPageView extends ConsumerWidget {
  const _MushafPageView({required this.pageNumber, required this.verses});

  final int pageNumber;
  final List<Verse> verses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioState = ref.watch(audioPlayerProvider);

    if (verses.isEmpty) {
      return Center(
        child: Text(
          'Page vide',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // En-tête : info juz + n° sourate de la première ayah de la page.
    final firstVerse = verses.first;
    final repo = ref.watch(quranRepositoryProvider).value;
    final surahName =
        repo != null ? repo.surahByNumber(firstVerse.surahNumber).nameArabic : '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Juz ${firstVerse.juz}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  surahName,
                  style: AppTypography.ayahSmall(theme.colorScheme.primary)
                      .copyWith(fontSize: 18),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  'p. $pageNumber',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 4,
                runSpacing: 8,
                children: [
                  for (final verse in verses)
                    _InlineAyah(
                      verse: verse,
                      isCurrent:
                          audioState.currentSurah == verse.surahNumber &&
                              audioState.currentAyah == verse.ayahInSurah,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineAyah extends ConsumerWidget {
  const _InlineAyah({required this.verse, required this.isCurrent});

  final Verse verse;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final highlight = isCurrent
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        ref.read(audioPlayerProvider.notifier).playVerse(
              surah: verse.surahNumber,
              ayah: verse.ayahInSurah,
            );
      },
      onLongPress: () => showVerseAudioMenu(context, verse),
      child: Container(
        decoration: BoxDecoration(
          color: highlight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: verse.arabicText,
                style: AppTypography.ayahMedium(theme.colorScheme.onSurface),
              ),
              TextSpan(
                text: ' ﴿${_arabicNumber(verse.ayahInSurah)}﴾ ',
                style: AppTypography.ayahSmall(theme.colorScheme.primary)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  static const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  String _arabicNumber(int n) {
    return n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join();
  }
}
