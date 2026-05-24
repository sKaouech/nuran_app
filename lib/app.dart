import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_mode_provider.dart';

/// Le router est exposé via un provider pour pouvoir injecter `ref` dedans
/// (et écouter les changements de kidsMode pour rediriger).
final _routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

class NuranApp extends ConsumerWidget {
  const NuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(_routerProvider);

    // Mode sépia : on substitue le theme "light" par sépia.
    final lightTheme =
        themeMode == AppThemeMode.sepia ? AppTheme.sepia : AppTheme.light;

    return MaterialApp.router(
      title: 'Nuran',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: AppTheme.dark,
      themeMode: themeMode.materialMode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routerConfig: router,
    );
  }
}
