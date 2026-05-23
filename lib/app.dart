import 'package:flutter/material.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/kids/presentation/pages/madrasa_page.dart';
import 'features/kids/presentation/providers/kids_mode_provider.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_mode_provider.dart';

class NuranApp extends ConsumerWidget {
  const NuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final kidsState = ref.watch(kidsModeProvider);

    // Mode sépia : on substitue le theme "light" par sépia.
    final lightTheme =
        themeMode == AppThemeMode.sepia ? AppTheme.sepia : AppTheme.light;

    // Mode enfant : on bascule sur une app simplifiée sans router complexe.
    if (kidsState.kidsModeEnabled) {
      return MaterialApp(
        title: 'Nuran',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: AppTheme.dark,
        themeMode: themeMode.materialMode,
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const MadrasaPage(),
      );
    }

    return MaterialApp.router(
      title: 'Nuran',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: AppTheme.dark,
      themeMode: themeMode.materialMode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routerConfig: _router,
    );
  }
}

final _router = buildRouter();
