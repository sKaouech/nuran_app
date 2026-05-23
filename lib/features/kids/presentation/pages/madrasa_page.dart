import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/presentation/pages/surah_reader_page.dart';
import '../../../../shared/widgets/fade_in_on_appear.dart';
import '../providers/kids_mode_provider.dart';
import 'parent_pin_page.dart';

/// Madrasa = page d'accueil enfant.
/// - Liste des sourates du Juz 'Amma (78 à 114) en grille colorée
/// - Récitateur lent par défaut (Husary Muallim)
/// - Bouton "Sortie parent" en haut à droite avec PIN
class MadrasaPage extends ConsumerStatefulWidget {
  const MadrasaPage({super.key});

  @override
  ConsumerState<MadrasaPage> createState() => _MadrasaPageState();
}

class _MadrasaPageState extends ConsumerState<MadrasaPage> {
  @override
  void initState() {
    super.initState();
    // Au lancement du mode enfant, on bascule sur Husary Muallim (récitateur lent)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayerProvider.notifier).setReciter('husary_muallim');
    });
  }

  /// Palette de couleurs douces pour les cartes sourates (cycle).
  static const _cardColors = [
    Color(0xFFA7D7C5), // vert pâle
    Color(0xFFF5E6B8), // or pâle
    Color(0xFFEED9C4), // brun pâle
    Color(0xFFFFD1B3), // pêche
    Color(0xFFD4E6F5), // bleu pâle
    Color(0xFFE8DAEF), // violet pâle
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncRepo = ref.watch(quranRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          '🌟 Madrasa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Sortie parent',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => _showExitPin(context),
          ),
        ],
      ),
      body: asyncRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          // Juz 'Amma : sourates 78 à 114 (en lecture inverse : on commence par la plus connue)
          final juzAmma = repo.surahs.where((s) => s.number >= 78).toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: theme.colorScheme.primary,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'As-salāmu ʿalaykum 👋',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Choisis une sourate à apprendre',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull / 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.record_voice_over,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Récitateur : Al-Husary (lent)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: juzAmma.length,
                  itemBuilder: (context, index) {
                    final surah = juzAmma[index];
                    final color = _cardColors[index % _cardColors.length];
                    return FadeInOnAppear(
                      delay: Duration(milliseconds: 30 * index),
                      child: _MadrasaSurahCard(
                        surahNumber: surah.number,
                        nameArabic: surah.nameArabic,
                        nameEnglish: surah.nameEnglish,
                        versesCount: surah.versesCount,
                        cardColor: color,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SurahReaderPage(
                                surahNumber: surah.number,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showExitPin(BuildContext context) async {
    final state = ref.read(kidsModeProvider);
    if (!state.hasPinSet) {
      // Pas de PIN défini → on sort directement (cas migration)
      await ref.read(kidsModeProvider.notifier).tryExitKidsMode('');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ParentPinPage.verify()),
    );
  }
}

class _MadrasaSurahCard extends StatelessWidget {
  const _MadrasaSurahCard({
    required this.surahNumber,
    required this.nameArabic,
    required this.nameEnglish,
    required this.versesCount,
    required this.cardColor,
    required this.onTap,
  });

  final int surahNumber;
  final String nameArabic;
  final String nameEnglish;
  final int versesCount;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$surahNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E4F),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameArabic,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1B1A),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nameEnglish,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1B1A),
                    ),
                  ),
                  Text(
                    '$versesCount versets',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceLight.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
