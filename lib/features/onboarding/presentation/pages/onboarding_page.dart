import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../../shared/widgets/haptics.dart';
import '../providers/onboarding_provider.dart';

/// Écran d'onboarding 3 pages présenté au premier lancement.
///
/// Le tout premier choix proposé est la **langue de l'app** : on ne peut pas
/// afficher des textes français/anglais en RTL ou des chiffres mal placés,
/// donc on impose à l'utilisateur de confirmer sa langue avant de continuer.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  /// Slides traduits par langue. La structure est identique pour les 3
  /// langues — on évite l'app_localizations.arb pour rester self-contained
  /// et facile à éditer sans regen.
  static const Map<String, List<_OnboardingSlide>> _slidesByLang = {
    'fr': [
      _OnboardingSlide(
        emoji: '📖',
        title: 'Bienvenue dans Nuran',
        subtitle: 'Mémorisez et révisez le Coran, jour après jour.',
        bullets: [
          '6236 versets en Hafs Uthmani',
          '10 récitateurs gratuits',
          'Mode mushaf Madinah complet',
        ],
      ),
      _OnboardingSlide(
        emoji: '🧠',
        title: 'Murajaa intelligente',
        subtitle: 'Le premier algorithme FSRS v4 appliqué au Coran.',
        bullets: [
          'Révision au bon moment, ni trop tôt ni trop tard',
          '90% de rétention long-terme',
          'Heatmap "Force du souvenir" par juz',
        ],
      ),
      _OnboardingSlide(
        emoji: '🎯',
        title: 'Tous les outils Hifz',
        subtitle: 'De multiples modes pour mémoriser efficacement.',
        bullets: [
          'Écoute & Répète avec masquage progressif',
          'Quiz QCM pour s\'auto-tester',
          'Vérification ASR de la récitation',
        ],
      ),
    ],
    'ar': [
      _OnboardingSlide(
        emoji: '📖',
        title: 'مرحبًا بك في نوران',
        subtitle: 'احفظ وراجع القرآن الكريم يومًا بعد يوم.',
        bullets: [
          '٦٢٣٦ آية برواية حفص',
          '١٠ قراء مجانًا',
          'مصحف المدينة كامل',
        ],
      ),
      _OnboardingSlide(
        emoji: '🧠',
        title: 'مراجعة ذكية',
        subtitle: 'أول تطبيق قرآني يعتمد خوارزمية FSRS v4.',
        bullets: [
          'المراجعة في الوقت المناسب',
          '٩٠٪ نسبة احتفاظ طويل الأمد',
          'خريطة "قوة الحفظ" لكل جزء',
        ],
      ),
      _OnboardingSlide(
        emoji: '🎯',
        title: 'كل أدوات الحفظ',
        subtitle: 'وسائل متعددة للحفظ بفعالية.',
        bullets: [
          'استمع وكرر مع إخفاء تدريجي',
          'أسئلة اختيار من متعدد',
          'تحقق صوتي من التلاوة',
        ],
      ),
    ],
    'en': [
      _OnboardingSlide(
        emoji: '📖',
        title: 'Welcome to Nuran',
        subtitle: 'Memorize and review the Quran, day after day.',
        bullets: [
          '6236 verses in Hafs Uthmani',
          '10 free reciters',
          'Full Madinah mushaf mode',
        ],
      ),
      _OnboardingSlide(
        emoji: '🧠',
        title: 'Smart Murajaa',
        subtitle: 'The first FSRS v4 algorithm applied to the Quran.',
        bullets: [
          'Review at the right moment',
          '90% long-term retention',
          '"Memory strength" heatmap per juz',
        ],
      ),
      _OnboardingSlide(
        emoji: '🎯',
        title: 'All Hifz tools',
        subtitle: 'Multiple modes to memorize efficiently.',
        bullets: [
          'Listen & Repeat with progressive masking',
          'MCQ quiz for self-testing',
          'ASR recitation verification',
        ],
      ),
    ],
  };

  /// Strings UI traduits (boutons Passer, Suivant, Commencer).
  static const Map<String, _OnboardingStrings> _stringsByLang = {
    'fr': _OnboardingStrings(
      skip: 'Passer',
      next: 'Suivant',
      start: 'Commencer',
      pickLanguage: 'Choisissez votre langue',
    ),
    'ar': _OnboardingStrings(
      skip: 'تخطّي',
      next: 'التالي',
      start: 'ابدأ',
      pickLanguage: 'اختر لغتك',
    ),
    'en': _OnboardingStrings(
      skip: 'Skip',
      next: 'Next',
      start: 'Start',
      pickLanguage: 'Choose your language',
    ),
  };

  Future<void> _finish() async {
    Haptics.success();
    await ref.read(onboardingCompletedProvider.notifier).markCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    final slides = _slidesByLang[lang] ?? _slidesByLang['fr']!;
    final strings = _stringsByLang[lang] ?? _stringsByLang['fr']!;
    final isLast = _currentIndex == slides.length - 1;
    final isRtl = lang == 'ar';

    // On force la directionnalité au niveau du Directionality wrapper pour
    // garantir une UI cohérente même si la locale système diffère de l'app.
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Barre du haut : sélecteur de langue + bouton Passer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _LanguageSwitcher(current: lang),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: Text(strings.skip),
                    ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    return _SlideView(slide: slides[index]);
                  },
                ),
              ),

              // Indicateur de page
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final isActive = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Bouton principal
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    // En RTL, on inverse l'icône pour pointer dans le bon sens.
                    icon: Icon(isLast
                        ? Icons.check
                        : (isRtl
                            ? Icons.arrow_back
                            : Icons.arrow_forward)),
                    label: Text(isLast ? strings.start : strings.next),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends ConsumerWidget {
  const _LanguageSwitcher({required this.current});
  final String current;

  static const _options = [
    ('fr', 'FR'),
    ('ar', 'ع'),
    ('en', 'EN'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (code, label) in _options)
            _LanguageChip(
              code: code,
              label: label,
              selected: code == current,
              onTap: () {
                Haptics.selection();
                ref
                    .read(localeProvider.notifier)
                    .setLocale(Locale(code));
              },
            ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: selected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> bullets;
}

class _OnboardingStrings {
  const _OnboardingStrings({
    required this.skip,
    required this.next,
    required this.start,
    required this.pickLanguage,
  });
  final String skip;
  final String next;
  final String start;
  final String pickLanguage;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slide.emoji,
            style: const TextStyle(fontSize: 100),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            slide.title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slide.subtitle,
            style: AppTypography.translation(
              theme.colorScheme.onSurfaceVariant,
            ).copyWith(fontSize: 18, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          ...slide.bullets.map((bullet) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        bullet,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
