import 'package:flutter/foundation.dart';

/// État d'une carte FSRS.
/// - [newCard] : jamais vue
/// - [learning] : en apprentissage initial (étapes courtes)
/// - [review] : en révision long-terme (intervalle en jours)
/// - [relearning] : oubliée, en ré-apprentissage
enum FsrsState { newCard, learning, review, relearning }

/// Notation utilisateur après récitation d'un verset.
/// Maps to FSRS grades: Again=1, Hard=2, Good=3, Easy=4.
enum FsrsRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const FsrsRating(this.value);
  final int value;
}

extension FsrsStateX on FsrsState {
  String get storageKey => name;
  static FsrsState fromStorage(String? v) {
    if (v == null) return FsrsState.newCard;
    return FsrsState.values.firstWhere(
      (s) => s.name == v,
      orElse: () => FsrsState.newCard,
    );
  }
}

/// Carte FSRS pour un verset donné.
@immutable
class FsrsCard {
  const FsrsCard({
    required this.verseGlobalIndex,
    required this.stability,
    required this.difficulty,
    required this.dueAt,
    required this.lastReviewAt,
    required this.state,
    required this.reps,
    required this.lapses,
  });

  /// Index global du verset (1..6236).
  final int verseGlobalIndex;

  /// "Stability" en jours : durée pendant laquelle on prédit que la
  /// retrievability restera &gt;= request_retention. Plus c'est haut, plus
  /// l'intervalle suivant sera long.
  final double stability;

  /// "Difficulty" entre 1.0 (très facile) et 10.0 (très difficile).
  /// Augmente avec les Again/Hard, diminue avec les Easy.
  final double difficulty;

  /// Date à laquelle ce verset devrait être revu (epoch millis).
  final int dueAt;

  /// Dernière révision (epoch millis, 0 si jamais revu).
  final int lastReviewAt;

  final FsrsState state;
  final int reps;
  final int lapses;

  /// Retrievability : probabilité de se souvenir maintenant.
  /// Formule FSRS v4 : R(t,S) = (1 + t/(9*S))^(-1)
  double retrievabilityAt(DateTime now) {
    if (lastReviewAt == 0 || stability <= 0) return 0;
    final elapsed = (now.millisecondsSinceEpoch - lastReviewAt) / 86400000.0;
    if (elapsed <= 0) return 1.0;
    return 1.0 / (1.0 + elapsed / (9.0 * stability));
  }

  /// Est-ce que ce verset est dû maintenant ?
  bool isDueAt(DateTime now) => now.millisecondsSinceEpoch >= dueAt;

  FsrsCard copyWith({
    double? stability,
    double? difficulty,
    int? dueAt,
    int? lastReviewAt,
    FsrsState? state,
    int? reps,
    int? lapses,
  }) {
    return FsrsCard(
      verseGlobalIndex: verseGlobalIndex,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueAt: dueAt ?? this.dueAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      state: state ?? this.state,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
    );
  }

  Map<String, dynamic> toJson() => {
        'v': verseGlobalIndex,
        's': stability,
        'd': difficulty,
        'due': dueAt,
        'lr': lastReviewAt,
        'st': state.storageKey,
        'r': reps,
        'l': lapses,
      };

  factory FsrsCard.fromJson(Map<String, dynamic> json) => FsrsCard(
        verseGlobalIndex: json['v'] as int,
        stability: (json['s'] as num).toDouble(),
        difficulty: (json['d'] as num).toDouble(),
        dueAt: json['due'] as int,
        lastReviewAt: json['lr'] as int,
        state: FsrsStateX.fromStorage(json['st'] as String?),
        reps: json['r'] as int,
        lapses: json['l'] as int,
      );

  /// Nouvelle carte pour un verset, jamais revue.
  factory FsrsCard.newFor(int verseGlobalIndex) => FsrsCard(
        verseGlobalIndex: verseGlobalIndex,
        stability: 0,
        difficulty: 0,
        dueAt: 0,
        lastReviewAt: 0,
        state: FsrsState.newCard,
        reps: 0,
        lapses: 0,
      );
}
