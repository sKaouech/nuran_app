import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_provider.dart';

const _kTranslationKey = 'reading_translation';
const _kFontScaleKey = 'reading_font_scale';
const _kTajwidColorsKey = 'reading_tajwid_colors';

/// Préférences de lecture : traduction par défaut et échelle de la police arabe.
@immutable
class ReadingPreferences {
  const ReadingPreferences({
    required this.translationLang,
    required this.fontScale,
    required this.tajwidColorsEnabled,
  });

  /// Code langue de la traduction affichée ('fr' ou 'en').
  final String translationLang;

  /// Multiplicateur appliqué à la taille de la police arabe (0.8 à 1.5).
  final double fontScale;

  /// Active la coloration des règles tajwid (madd, ghunnah, qalqalah).
  final bool tajwidColorsEnabled;

  ReadingPreferences copyWith({
    String? translationLang,
    double? fontScale,
    bool? tajwidColorsEnabled,
  }) {
    return ReadingPreferences(
      translationLang: translationLang ?? this.translationLang,
      fontScale: fontScale ?? this.fontScale,
      tajwidColorsEnabled: tajwidColorsEnabled ?? this.tajwidColorsEnabled,
    );
  }
}

class ReadingPreferencesNotifier extends StateNotifier<ReadingPreferences> {
  ReadingPreferencesNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ReadingPreferences _load(SharedPreferences prefs) {
    return ReadingPreferences(
      translationLang: prefs.getString(_kTranslationKey) ?? 'fr',
      fontScale: prefs.getDouble(_kFontScaleKey) ?? 1.0,
      tajwidColorsEnabled: prefs.getBool(_kTajwidColorsKey) ?? false,
    );
  }

  Future<void> setTranslation(String lang) async {
    state = state.copyWith(translationLang: lang);
    await _prefs.setString(_kTranslationKey, lang);
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale.clamp(0.8, 1.5));
    await _prefs.setDouble(_kFontScaleKey, state.fontScale);
  }

  Future<void> setTajwidColorsEnabled(bool enabled) async {
    state = state.copyWith(tajwidColorsEnabled: enabled);
    await _prefs.setBool(_kTajwidColorsKey, enabled);
  }
}

final readingPreferencesProvider =
    StateNotifierProvider<ReadingPreferencesNotifier, ReadingPreferences>(
        (ref) {
  return ReadingPreferencesNotifier(ref.watch(sharedPreferencesProvider));
});
