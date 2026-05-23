import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';

const _kKidsEnabledKey = 'kids_mode_enabled';
const _kParentPinKey = 'kids_parent_pin';

/// État du mode enfant.
@immutable
class KidsState {
  const KidsState({
    required this.kidsModeEnabled,
    required this.parentPin,
  });

  /// True quand on est actuellement en mode enfant (UI bridée).
  final bool kidsModeEnabled;

  /// PIN parental (4 chiffres). Vide = pas encore défini.
  final String parentPin;

  bool get hasPinSet => parentPin.length == 4;

  KidsState copyWith({bool? kidsModeEnabled, String? parentPin}) {
    return KidsState(
      kidsModeEnabled: kidsModeEnabled ?? this.kidsModeEnabled,
      parentPin: parentPin ?? this.parentPin,
    );
  }
}

class KidsModeNotifier extends StateNotifier<KidsState> {
  KidsModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static KidsState _load(SharedPreferences prefs) {
    return KidsState(
      kidsModeEnabled: prefs.getBool(_kKidsEnabledKey) ?? false,
      parentPin: prefs.getString(_kParentPinKey) ?? '',
    );
  }

  Future<void> setPin(String pin) async {
    if (pin.length != 4) return;
    state = state.copyWith(parentPin: pin);
    await _prefs.setString(_kParentPinKey, pin);
  }

  Future<void> enterKidsMode() async {
    state = state.copyWith(kidsModeEnabled: true);
    await _prefs.setBool(_kKidsEnabledKey, true);
  }

  /// Quitte le mode enfant si le PIN fourni correspond.
  Future<bool> tryExitKidsMode(String pinAttempt) async {
    if (pinAttempt != state.parentPin) return false;
    state = state.copyWith(kidsModeEnabled: false);
    await _prefs.setBool(_kKidsEnabledKey, false);
    return true;
  }
}

final kidsModeProvider =
    StateNotifierProvider<KidsModeNotifier, KidsState>((ref) {
  return KidsModeNotifier(ref.watch(sharedPreferencesProvider));
});
