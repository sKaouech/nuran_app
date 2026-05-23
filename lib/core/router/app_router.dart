import 'package:go_router/go_router.dart';

import '../../features/hifz/presentation/pages/hifz_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/murajaa/presentation/pages/murajaa_page.dart';
import '../../features/quran_reader/presentation/pages/quran_reader_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'routes.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
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
