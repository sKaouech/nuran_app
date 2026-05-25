import 'package:flutter/material.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../features/audio_player/presentation/widgets/mini_player.dart';

/// Scaffold avec NavigationBar bas, partagé par les 5 tabs principales.
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _tabs = <_TabInfo>[
    _TabInfo(Routes.home, Icons.home_outlined, Icons.home_rounded),
    _TabInfo(Routes.read, Icons.menu_book_outlined, Icons.menu_book_rounded),
    _TabInfo(Routes.hifz, Icons.school_outlined, Icons.school_rounded),
    _TabInfo(Routes.murajaa, Icons.refresh_outlined, Icons.refresh),
    _TabInfo(Routes.settings, Icons.settings_outlined, Icons.settings_rounded),
  ];

  int _indexFromLocation(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].route ||
          (_tabs[i].route != Routes.home && location.startsWith(_tabs[i].route))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexFromLocation(location);
    final l10n = AppL10n.of(context);
    final labels = [
      l10n.tabHome,
      l10n.tabRead,
      l10n.tabHifz,
      l10n.tabMurajaa,
      l10n.tabSettings,
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (i) {
              // Quand des pages sont empilées par-dessus le shell (sourate
              // ouverte en push, downloads, etc.), il faut les dépiler avant
              // de changer d'onglet sinon le tap "ne fait rien".
              //
              // Le Navigator standard de Flutter (pas le rootNavigator de
              // go_router) gère ces push MaterialPageRoute → on dépile dessus.
              final nav = Navigator.of(context);
              while (nav.canPop()) {
                nav.pop();
              }
              context.go(_tabs[i].route);
            },
            destinations: [
              for (var i = 0; i < _tabs.length; i++)
                NavigationDestination(
                  icon: Icon(_tabs[i].icon),
                  selectedIcon: Icon(_tabs[i].selectedIcon),
                  label: labels[i],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo(this.route, this.icon, this.selectedIcon);
  final String route;
  final IconData icon;
  final IconData selectedIcon;
}
