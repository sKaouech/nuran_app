import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/haptics.dart';
import '../providers/onboarding_provider.dart';

/// Écran d'onboarding 3 pages présenté au premier lancement.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  static const _slides = [
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
  ];

  Future<void> _finish() async {
    Haptics.success();
    await ref.read(onboardingCompletedProvider.notifier).markCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Passer'),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  return _SlideView(slide: _slides[index]);
                },
              ),
            ),

            // Indicateur de page
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
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
                  icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                  label: Text(isLast ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
          ],
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
