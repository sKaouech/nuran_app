import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';

const _kKey = 'kids_stars_total';

/// Système d'étoiles pour récompenser l'enfant.
/// - 1 étoile par verset écouté en mode kid
/// - 3 étoiles par quiz réussi (≥80%)
/// - 1 étoile par quiz raté (mais joué) pour encourager
class KidsStarsNotifier extends StateNotifier<int> {
  KidsStarsNotifier(this._prefs) : super(_prefs.getInt(_kKey) ?? 0);

  final SharedPreferences _prefs;

  Future<void> award(int amount) async {
    if (amount <= 0) return;
    state = state + amount;
    await _prefs.setInt(_kKey, state);
  }

  Future<void> reset() async {
    state = 0;
    await _prefs.setInt(_kKey, 0);
  }
}

final kidsStarsProvider =
    StateNotifierProvider<KidsStarsNotifier, int>((ref) {
  return KidsStarsNotifier(ref.watch(sharedPreferencesProvider));
});

/// Helper pour décider quel "badge" afficher selon le nombre d'étoiles.
String kidsBadgeLabel(int stars) {
  if (stars < 5) return 'Débutant 🌱';
  if (stars < 20) return 'Apprenti 📖';
  if (stars < 50) return 'Étudiant 🎓';
  if (stars < 100) return 'Hafiz junior ⭐';
  if (stars < 250) return 'Étoile montante 🌟';
  return 'Hafiz d\'or 🏆';
}
