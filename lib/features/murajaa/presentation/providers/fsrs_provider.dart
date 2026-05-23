import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../domain/fsrs_algorithm.dart';
import '../../domain/fsrs_card.dart';

const _kKey = 'fsrs_cards_v1';

/// Notifier qui maintient la map verse_index → FsrsCard et persiste en JSON.
class FsrsCardsNotifier extends StateNotifier<Map<int, FsrsCard>> {
  FsrsCardsNotifier(this._prefs, this._algorithm) : super(_load(_prefs));

  final SharedPreferences _prefs;
  final FsrsAlgorithm _algorithm;

  FsrsAlgorithm get algorithm => _algorithm;

  static Map<int, FsrsCard> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null) return const {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) =>
          MapEntry(int.parse(k), FsrsCard.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return const {};
    }
  }

  Future<void> _persist() async {
    final encoded = json.encode(
      state.map((k, v) => MapEntry(k.toString(), v.toJson())),
    );
    await _prefs.setString(_kKey, encoded);
  }

  FsrsCard cardFor(int verseGlobalIndex) =>
      state[verseGlobalIndex] ?? FsrsCard.newFor(verseGlobalIndex);

  /// Note un verset avec une note FSRS et reprogramme la prochaine échéance.
  Future<FsrsCard> rate(int verseGlobalIndex, FsrsRating rating) async {
    final current = cardFor(verseGlobalIndex);
    final updated = _algorithm.schedule(current, rating, DateTime.now());
    final next = Map<int, FsrsCard>.from(state)..[verseGlobalIndex] = updated;
    state = next;
    await _persist();
    return updated;
  }

  /// Ajoute une carte sans la noter (par ex. quand on marque "En cours").
  /// Si la carte existe déjà, no-op.
  Future<void> registerIfAbsent(int verseGlobalIndex) async {
    if (state.containsKey(verseGlobalIndex)) return;
    final next = Map<int, FsrsCard>.from(state)
      ..[verseGlobalIndex] = FsrsCard.newFor(verseGlobalIndex);
    state = next;
    await _persist();
  }

  Future<void> removeCard(int verseGlobalIndex) async {
    if (!state.containsKey(verseGlobalIndex)) return;
    final next = Map<int, FsrsCard>.from(state)..remove(verseGlobalIndex);
    state = next;
    await _persist();
  }

  /// Stats globales pour le dashboard.
  ({int total, int due, int learning, int review, int relearning})
      stats() {
    final now = DateTime.now();
    var due = 0;
    var learning = 0;
    var review = 0;
    var relearning = 0;
    for (final c in state.values) {
      if (c.isDueAt(now)) due++;
      switch (c.state) {
        case FsrsState.newCard:
          break;
        case FsrsState.learning:
          learning++;
          break;
        case FsrsState.review:
          review++;
          break;
        case FsrsState.relearning:
          relearning++;
          break;
      }
    }
    return (
      total: state.length,
      due: due,
      learning: learning,
      review: review,
      relearning: relearning,
    );
  }
}

final fsrsAlgorithmProvider = Provider<FsrsAlgorithm>((ref) {
  return FsrsAlgorithm();
});

final fsrsCardsProvider =
    StateNotifierProvider<FsrsCardsNotifier, Map<int, FsrsCard>>((ref) {
  return FsrsCardsNotifier(
    ref.watch(sharedPreferencesProvider),
    ref.watch(fsrsAlgorithmProvider),
  );
});

/// File Murajaa : versets dont le due_date est dépassé, triés par urgence
/// (les plus en retard d'abord, puis par retrievability croissante).
final murajaaQueueProvider = Provider<List<Verse>>((ref) {
  final cards = ref.watch(fsrsCardsProvider);
  final asyncRepo = ref.watch(quranRepositoryProvider);
  final repo = asyncRepo.value;
  if (repo == null) return const [];

  final now = DateTime.now();
  final dueCards = cards.values.where((c) => c.isDueAt(now)).toList();

  // Tri : retrievability croissante (les plus oubliés d'abord)
  dueCards.sort((a, b) {
    return a.retrievabilityAt(now).compareTo(b.retrievabilityAt(now));
  });

  return [for (final c in dueCards) repo.verses[c.verseGlobalIndex - 1]];
});
