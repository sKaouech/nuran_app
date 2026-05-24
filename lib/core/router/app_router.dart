import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/hifz/presentation/pages/hifz_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/kids/presentation/pages/madrasa_page.dart';
import '../../features/kids/presentation/providers/kids_mode_provider.dart';
import '../../features/murajaa/presentation/pages/murajaa_page.dart';
import '../../features/quran_reader/presentation/pages/quran_reader_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'routes.dart';

/// Pont entre Riverpod et go_router : convertit n'importe quel provider en
/// `Listenable` pour `refreshListenable`. Quand le provider change, le router
/// re-évalue ses redirects.
class RiverpodListenable extends ChangeNotifier {
  RiverpodListenable(Ref ref, ProviderBase<Object?> provider) {
    ref.listen<Object?>(provider, (_, _) => notifyListeners());
  }
}

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: RiverpodListenable(ref, kidsModeProvider),
    redirect: (context, state) {
      final kidsEnabled = ref.read(kidsModeProvider).kidsModeEnabled;
      final isOnMadrasa = state.matchedLocation == Routes.madrasa;

      // Mode enfant actif : on force /madrasa (sauf si déjà dessus)
      if (kidsEnabled && !isOnMadrasa) return Routes.madrasa;
      // Mode enfant désactivé mais on est sur /madrasa : retour home
      if (!kidsEnabled && isOnMadrasa) return Routes.home;
      return null;
    },
    routes: [
      // Route plein écran hors shell : Madrasa
      GoRoute(
        path: Routes.madrasa,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MadrasaPage()),
      ),
      // Shell principal avec les 5 tabs
      ShellRoute(
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
