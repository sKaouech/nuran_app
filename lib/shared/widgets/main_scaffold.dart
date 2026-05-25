import 'package:flutter/material.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../features/audio_player/presentation/widgets/mini_player.dart';

/// Scaffold avec NavigationBar bas, partagé par les 5 tabs principales.
///
/// **Sélection du tab actif** : on combine deux sources :
/// 1. Le path go_router courant (cas nominal — tap sur un tab).
/// 2. Un fallback mémorisé localement quand l'utilisateur a poussé une
///    sous-page par-dessus le shell (ex: SurahReaderPage) — dans ce cas
///    le path go_router ne change pas mais on veut quand même refléter
///    le tab d'origine si la navigation se fait inter-tabs.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _tabs = <_TabInfo>[
    _TabInfo(Routes.home, Icons.home_outlined, Icons.home_rounded),
    _TabInfo(Routes.read, Icons.menu_book_outlined, Icons.menu_book_rounded),
    _TabInfo(Routes.hifz, Icons.school_outlined, Icons.school_rounded),
    _TabInfo(Routes.murajaa, Icons.refresh_outlined, Icons.refresh),
    _TabInfo(Routes.settings, Icons.settings_outlined, Icons.settings_rounded),
  ];

  int _indexFromLocation(String location) {
    // Home matche uniquement le path exact "/".
    if (location == Routes.home) return 0;
    for (var i = 1; i < _tabs.length; i++) {
      if (location == _tabs[i].route ||
          location.startsWith('${_tabs[i].route}/')) {
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
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (i) {
              // Dépiler TOUT ce qui a été poussé par-dessus le shell.
              //
              // Les MaterialPageRoute (SurahReaderPage, DownloadsPage, etc.)
              // sont push sur le root navigator, alors que le shell est géré
              // par go_router. On dépile donc les deux niveaux :
              //  - rootNavigator pour les MaterialPageRoute
              //  - navigator local pour go_router subroutes
              final rootNav = Navigator.of(context, rootNavigator: true);
              while (rootNav.canPop()) {
                rootNav.pop();
              }
              // Toujours faire le go(), même si le path actuel est déjà
              // sur le bon tab — c'est nécessaire car le path peut avoir
              // dérivé si l'utilisateur naviguait entre tabs depuis une
              // page push.
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
