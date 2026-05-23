import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';
import '../../domain/memorization_status.dart';

const _kStorageKey = 'memorization_state_v1';

/// État global : map globalIndex (1..6236) → MemorizationStatus.
/// Persisté dans SharedPreferences sous forme JSON compact.
class MemorizationNotifier
    extends StateNotifier<Map<int, MemorizationStatus>> {
  MemorizationNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Map<int, MemorizationStatus> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kStorageKey);
    if (raw == null) return const {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(int.parse(k), MemorizationStatusX.fromStorage(v as String)),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> _persist() async {
    final encoded = json.encode(
      state.map((k, v) => MapEntry(k.toString(), v.storageKey)),
    );
    await _prefs.setString(_kStorageKey, encoded);
  }

  MemorizationStatus statusOf(int globalIndex) =>
      state[globalIndex] ?? MemorizationStatus.notStarted;

  Future<void> setStatus(int globalIndex, MemorizationStatus status) async {
    final next = Map<int, MemorizationStatus>.from(state);
    if (status == MemorizationStatus.notStarted) {
      next.remove(globalIndex);
    } else {
      next[globalIndex] = status;
    }
    state = next;
    await _persist();
  }

  /// Stats agrégées pour le dashboard.
  int countByStatus(MemorizationStatus status) =>
      state.values.where((s) => s == status).length;

  int get totalMarked => state.length;
}

final memorizationProvider = StateNotifierProvider<MemorizationNotifier,
    Map<int, MemorizationStatus>>((ref) {
  return MemorizationNotifier(ref.watch(sharedPreferencesProvider));
});
