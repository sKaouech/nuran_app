import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_provider.dart';

const _kThemeKey = 'app_theme_mode';

/// Modes thème étendus : on ajoute "sepia" pour la lecture longue du mushaf.
enum AppThemeMode { system, light, dark, sepia }

extension AppThemeModeX on AppThemeMode {
  /// Map vers le ThemeMode standard de MaterialApp.
  /// Sépia est traité comme un thème "light" custom au niveau de l'app.
  ThemeMode get materialMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.sepia => ThemeMode.light,
      };
}

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_initial(_prefs));

  final SharedPreferences _prefs;

  static AppThemeMode _initial(SharedPreferences prefs) {
    final saved = prefs.getString(_kThemeKey);
    if (saved == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeKey, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});
