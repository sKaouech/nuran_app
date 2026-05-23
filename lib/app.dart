import 'package:flutter/material.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_mode_provider.dart';

class NuranApp extends ConsumerWidget {
  const NuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Mode sépia : on substitue le theme "light" par sépia.
    final lightTheme =
        themeMode == AppThemeMode.sepia ? AppTheme.sepia : AppTheme.light;

    return MaterialApp.router(
      title: 'Quran Hifz',
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
