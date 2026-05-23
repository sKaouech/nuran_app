import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_initial(_prefs));

  final SharedPreferences _prefs;

  static Locale _initial(SharedPreferences prefs) {
    final saved = prefs.getString(_kLocaleKey);
    if (saved == null) return const Locale('fr');
    return Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});

const supportedLocales = <Locale>[
  Locale('fr'),
  Locale('ar'),
  Locale('en'),
];
