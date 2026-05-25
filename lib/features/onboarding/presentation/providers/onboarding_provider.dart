import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';

const _kKey = 'onboarding_completed_v1';

/// True quand l'utilisateur a vu l'onboarding au moins une fois.
/// Au premier lancement, false → on présente l'onboarding.
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._prefs)
      : super(_prefs.getBool(_kKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> markCompleted() async {
    state = true;
    await _prefs.setBool(_kKey, true);
  }

  /// Pour debug : réinitialiser pour revoir l'onboarding au prochain lancement.
  Future<void> reset() async {
    state = false;
    await _prefs.setBool(_kKey, false);
  }
}

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref.watch(sharedPreferencesProvider));
});
