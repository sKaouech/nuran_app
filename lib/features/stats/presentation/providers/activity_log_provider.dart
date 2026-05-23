import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';

const _kKey = 'activity_log_v1';

/// Log d'activité : map date (yyyy-MM-dd) → nombre de versets travaillés.
/// Utilisé pour : streak, courbe d'apprentissage, statistiques journalières.
class ActivityLogNotifier extends StateNotifier<Map<String, int>> {
  ActivityLogNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Map<String, int> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null) return const {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return const {};
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_kKey, json.encode(state));
  }

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Enregistre une activité aujourd'hui (incrémente le compteur).
  Future<void> logActivity({int versesWorked = 1}) async {
    final key = _dateKey(DateTime.now());
    final next = Map<String, int>.from(state);
    next[key] = (next[key] ?? 0) + versesWorked;
    state = next;
    await _persist();
  }

  /// Compte de versets travaillés à une date donnée (0 si pas d'activité).
  int countAt(DateTime date) => state[_dateKey(date)] ?? 0;

  /// Streak courant = nombre de jours consécutifs jusqu'à aujourd'hui (ou hier
  /// si rien fait aujourd'hui — on ne casse pas la série en cours de journée).
  int currentStreak() {
    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    var streak = 0;

    // Si rien aujourd'hui mais hier oui → on compte à partir d'hier.
    if (countAt(cursor) == 0) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (countAt(cursor) > 0) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Meilleure série historique.
  int bestStreak() {
    if (state.isEmpty) return 0;
    final dates = state.keys.toList()..sort();
    var best = 1;
    var current = 1;
    for (var i = 1; i < dates.length; i++) {
      final prev = DateTime.parse(dates[i - 1]);
      final curr = DateTime.parse(dates[i]);
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  /// Activité des N derniers jours (du plus ancien au plus récent).
  List<({DateTime date, int count})> lastDays(int days) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
    return [
      for (var i = 0; i < days; i++)
        (
          date: start.add(Duration(days: i)),
          count: countAt(start.add(Duration(days: i))),
        ),
    ];
  }

  int get totalActiveDays => state.length;
  int get totalVersesLogged =>
      state.values.fold(0, (sum, v) => sum + v);
}

final activityLogProvider =
    StateNotifierProvider<ActivityLogNotifier, Map<String, int>>((ref) {
  return ActivityLogNotifier(ref.watch(sharedPreferencesProvider));
});
