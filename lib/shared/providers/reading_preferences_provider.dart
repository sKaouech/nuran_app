import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_provider.dart';

const _kTranslationKey = 'reading_translation';
const _kFontScaleKey = 'reading_font_scale';

/// Préférences de lecture : traduction par défaut et échelle de la police arabe.
@immutable
class ReadingPreferences {
  const ReadingPreferences({
    required this.translationLang,
    required this.fontScale,
  });

  /// Code langue de la traduction affichée ('fr' ou 'en').
  final String translationLang;

  /// Multiplicateur appliqué à la taille de la police arabe (0.8 à 1.5).
  final double fontScale;

  ReadingPreferences copyWith({String? translationLang, double? fontScale}) {
    return ReadingPreferences(
      translationLang: translationLang ?? this.translationLang,
      fontScale: fontScale ?? this.fontScale,
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
}

final readingPreferencesProvider =
    StateNotifierProvider<ReadingPreferencesNotifier, ReadingPreferences>(
        (ref) {
  return ReadingPreferencesNotifier(ref.watch(sharedPreferencesProvider));
});
