import 'package:flutter/material.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart' show shellNavigatorKey;
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
              // Dépiler les pages push par-dessus le shell. Les pages comme
              // SurahReaderPage sont push avec Navigator.of(context) depuis
              // QuranReaderPage, ce qui les pose sur le navigator INTERNE
              // du shell (celui géré par go_router via shellNavigatorKey),
              // pas le rootNavigator.
              final shellNav = shellNavigatorKey.currentState;
              if (shellNav != null) {
                while (shellNav.canPop()) {
                  shellNav.pop();
                }
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
