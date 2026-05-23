import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';

const _kKey = 'bookmarks_v1';

/// Persiste un set de versets favoris (par globalIndex) avec note optionnelle.
class BookmarksNotifier
    extends StateNotifier<Map<int, String>> {
  BookmarksNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Map<int, String> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null) return const {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
    } catch (_) {
      return const {};
    }
  }

  Future<void> _persist() async {
    final encoded = json.encode(
      state.map((k, v) => MapEntry(k.toString(), v)),
    );
    await _prefs.setString(_kKey, encoded);
  }

  bool isBookmarked(int globalIndex) => state.containsKey(globalIndex);
  String? noteOf(int globalIndex) => state[globalIndex];

  Future<void> add(int globalIndex, {String note = ''}) async {
    final next = Map<int, String>.from(state)..[globalIndex] = note;
    state = next;
    await _persist();
  }

  Future<void> remove(int globalIndex) async {
    final next = Map<int, String>.from(state)..remove(globalIndex);
    state = next;
    await _persist();
  }

  Future<void> toggle(int globalIndex) async {
    if (isBookmarked(globalIndex)) {
      await remove(globalIndex);
    } else {
      await add(globalIndex);
    }
  }

  Future<void> setNote(int globalIndex, String note) async {
    if (!isBookmarked(globalIndex)) return;
    final next = Map<int, String>.from(state)..[globalIndex] = note;
    state = next;
    await _persist();
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, Map<int, String>>((ref) {
  return BookmarksNotifier(ref.watch(sharedPreferencesProvider));
});
