import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/hifz/presentation/pages/hifz_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/kids/presentation/pages/madrasa_page.dart';
import '../../features/kids/presentation/providers/kids_mode_provider.dart';
import '../../features/murajaa/presentation/pages/murajaa_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/quran_reader/presentation/pages/quran_reader_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'routes.dart';

/// Pont entre Riverpod et go_router : convertit n'importe quel provider en
/// `Listenable` pour `refreshListenable`. Quand le provider change, le router
/// re-évalue ses redirects.
class RiverpodListenable extends ChangeNotifier {
  RiverpodListenable(Ref ref, List<ProviderBase<Object?>> providers) {
    for (final provider in providers) {
      ref.listen<Object?>(provider, (_, _) => notifyListeners());
    }
  }
}

/// Clé du Navigator du shell. Exposée pour que MainScaffold puisse dépiler
/// les pages poussées par-dessus le shell (SurahReaderPage, DownloadsPage,
/// etc. — toutes celles push avec Navigator.of(context).push() depuis une
/// page tab) avant de basculer vers un autre onglet.
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: RiverpodListenable(ref, [
      kidsModeProvider,
      onboardingCompletedProvider,
    ]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 1. Onboarding non vu → on force /onboarding
      final onboardingDone = ref.read(onboardingCompletedProvider);
      if (!onboardingDone && loc != Routes.onboarding) {
        return Routes.onboarding;
      }
      // 2. Onboarding terminé mais on est sur /onboarding → home
      if (onboardingDone && loc == Routes.onboarding) {
        return Routes.home;
      }

      // 3. Mode enfant actif : on force /madrasa
      final kidsEnabled = ref.read(kidsModeProvider).kidsModeEnabled;
      final isOnMadrasa = loc == Routes.madrasa;
      if (kidsEnabled && !isOnMadrasa && loc != Routes.onboarding) {
        return Routes.madrasa;
      }
      if (!kidsEnabled && isOnMadrasa) return Routes.home;
      return null;
    },
    routes: [
      // Onboarding (premier lancement)
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingPage()),
      ),
      // Route plein écran hors shell : Madrasa
      GoRoute(
        path: Routes.madrasa,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MadrasaPage()),
      ),
      // Shell principal avec les 5 tabs
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: Routes.read,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: QuranReaderPage()),
          ),
          GoRoute(
            path: Routes.hifz,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HifzPage()),
          ),
          GoRoute(
            path: Routes.murajaa,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MurajaaPage()),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
}
