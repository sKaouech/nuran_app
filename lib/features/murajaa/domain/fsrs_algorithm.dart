import 'dart:math' as math;

import 'fsrs_card.dart';

/// Port Dart de l'algorithme FSRS v4 (Free Spaced Repetition Scheduler).
///
/// Référence : https://github.com/open-spaced-repetition/fsrs4anki
///
/// Cœur de l'algorithme :
/// - Stability (S) : nombre de jours pendant lesquels la rétention reste ≥ cible
/// - Difficulty (D) : difficulté intrinsèque de la carte (1.0 = facile, 10.0 = dur)
/// - Retrievability (R) : probabilité actuelle de se souvenir
/// - Intervalle suivant = S * (cible^(-1/decay) - 1) / factor
///
/// L'utilisateur note avec 4 grades :
/// - Again (1) : oublié, ré-apprentissage
/// - Hard (2) : difficile mais réussi
/// - Good (3) : réussi normalement
/// - Easy (4) : trop facile
class FsrsAlgorithm {
  FsrsAlgorithm({
    this.requestRetention = 0.9,
    this.maximumInterval = 36500, // 100 ans
    this.weights = defaultWeights,
  });

  /// Taux de rétention cible (0.9 = se souvenir 90% du temps).
  final double requestRetention;

  /// Intervalle maximum en jours.
  final int maximumInterval;

  /// 17 paramètres FSRS v4. Valeurs par défaut optimisées sur un large
  /// dataset Anki. Pourront être ré-optimisées plus tard avec les données
  /// utilisateur.
  final List<double> weights;

  static const List<double> defaultWeights = [
    0.4072, 1.1829, 3.1262, 15.4722, // w0-w3 : stability initiale par grade
    7.2102, 0.5316, 1.0651, 0.0234, // w4-w7 : difficulty
    1.616, 0.1544, 1.0824, 1.9813, // w8-w11 : stability factor
    0.0953, 0.2975, 2.2042, 0.2407, // w12-w15
    2.9466, // w16 : Hard factor
  ];

  /// Facteur pour calculer l'intervalle : I = S * (R^(-1/d) - 1) / f
  /// Avec d = 0.5 et f = 19/81 (constantes FSRS v4).
  static const double _decay = -0.5;
  static const double _factor = 19.0 / 81.0;

  /// Calcule la nouvelle carte après une review avec un grade donné.
  FsrsCard schedule(FsrsCard card, FsrsRating rating, DateTime now) {
    final elapsedDays = card.lastReviewAt == 0
        ? 0.0
        : (now.millisecondsSinceEpoch - card.lastReviewAt) / 86400000.0;

    switch (card.state) {
      case FsrsState.newCard:
        return _firstReview(card, rating, now);
      case FsrsState.learning:
      case FsrsState.relearning:
        return _learningStep(card, rating, now, elapsedDays);
      case FsrsState.review:
        return _reviewStep(card, rating, now, elapsedDays);
    }
  }

  /// Première review d'une carte nouvelle.
  FsrsCard _firstReview(FsrsCard card, FsrsRating rating, DateTime now) {
    final initialStability = _initialStability(rating);
    final initialDifficulty = _initialDifficulty(rating);
    final state = rating == FsrsRating.again
        ? FsrsState.learning
        : FsrsState.review;
    final intervalDays = rating == FsrsRating.again
        ? 0.0 // re-voir aujourd'hui
        : _nextInterval(initialStability);

    return card.copyWith(
      stability: initialStability,
      difficulty: initialDifficulty,
      state: state,
      reps: card.reps + 1,
      lapses: card.lapses,
      lastReviewAt: now.millisecondsSinceEpoch,
      dueAt: now
          .add(Duration(milliseconds: (intervalDays * 86400000).round()))
          .millisecondsSinceEpoch,
    );
  }

  /// Step en mode learning/relearning : intervalles courts (en minutes).
  FsrsCard _learningStep(
    FsrsCard card,
    FsrsRating rating,
    DateTime now,
    double elapsedDays,
  ) {
    final newDifficulty = _updateDifficulty(card.difficulty, rating);
    double newStability;
    FsrsState newState;
    double intervalDays;

    if (rating == FsrsRating.again) {
      // Reste en learning, re-voir dans 1 min
      newStability =
          _shortTermStability(card.stability, FsrsRating.again);
      newState = card.state;
      intervalDays = 1 / 1440.0; // 1 minute
    } else if (rating == FsrsRating.hard) {
      newStability = _shortTermStability(card.stability, FsrsRating.hard);
      newState = card.state;
      intervalDays = 5 / 1440.0; // 5 minutes
    } else if (rating == FsrsRating.good) {
      // Passe en review
      newStability = _shortTermStability(card.stability, FsrsRating.good);
      newState = FsrsState.review;
      intervalDays = _nextInterval(newStability);
    } else {
      // Easy : passe en review avec gros boost
      newStability = _shortTermStability(card.stability, FsrsRating.easy);
      newState = FsrsState.review;
      intervalDays = _nextInterval(newStability);
    }

    return card.copyWith(
      stability: newStability,
      difficulty: newDifficulty,
      state: newState,
      reps: card.reps + 1,
      lastReviewAt: now.millisecondsSinceEpoch,
      dueAt: now
          .add(Duration(milliseconds: (intervalDays * 86400000).round()))
          .millisecondsSinceEpoch,
    );
  }

  /// Step en mode review : recalcule S et D.
  FsrsCard _reviewStep(
    FsrsCard card,
    FsrsRating rating,
    DateTime now,
    double elapsedDays,
  ) {
    final retrievability = card.retrievabilityAt(now);
    final newDifficulty = _updateDifficulty(card.difficulty, rating);

    if (rating == FsrsRating.again) {
      // Lapse : la carte passe en relearning
      final newStability = _stabilityAfterFailure(
        card.difficulty,
        card.stability,
        retrievability,
      );
      return card.copyWith(
        stability: newStability,
        difficulty: newDifficulty,
        state: FsrsState.relearning,
        reps: card.reps + 1,
        lapses: card.lapses + 1,
        lastReviewAt: now.millisecondsSinceEpoch,
        dueAt: now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
      );
    } else {
      final newStability = _stabilityAfterSuccess(
        card.difficulty,
        card.stability,
        retrievability,
        rating,
      );
      final intervalDays = _nextInterval(newStability);
      return card.copyWith(
        stability: newStability,
        difficulty: newDifficulty,
        state: FsrsState.review,
        reps: card.reps + 1,
        lastReviewAt: now.millisecondsSinceEpoch,
        dueAt: now
            .add(Duration(milliseconds: (intervalDays * 86400000).round()))
            .millisecondsSinceEpoch,
      );
    }
  }

  // ---- Formules FSRS v4 ----

  /// Stability initiale = w[grade - 1].
  double _initialStability(FsrsRating r) {
    return math.max(0.1, weights[r.value - 1]);
  }

  /// Difficulty initiale : D0(G) = w4 - exp(w5 * (G - 1)) + 1
  double _initialDifficulty(FsrsRating r) {
    final d = weights[4] - math.exp(weights[5] * (r.value - 1)) + 1;
    return _clampDifficulty(d);
  }

  /// Difficulty après review : moyenne pondérée avec sa cible.
  double _updateDifficulty(double d, FsrsRating r) {
    final deltaD = -weights[6] * (r.value - 3);
    final dPrime = d + deltaD * (10 - d) / 9;
    // Mean reversion vers difficulté initiale pour Easy
    final mean = weights[7] * _initialDifficulty(FsrsRating.easy) +
        (1 - weights[7]) * dPrime;
    return _clampDifficulty(mean);
  }

  double _clampDifficulty(double d) => d.clamp(1.0, 10.0);

  /// Stability après succès en mode review.
  double _stabilityAfterSuccess(
    double d,
    double s,
    double r,
    FsrsRating rating,
  ) {
    final hardPenalty = rating == FsrsRating.hard ? weights[15] : 1.0;
    final easyBonus = rating == FsrsRating.easy ? weights[16] : 1.0;
    final factor = math.exp(weights[8]) *
        (11 - d) *
        math.pow(s, -weights[9]) *
        (math.exp((1 - r) * weights[10]) - 1) *
        hardPenalty *
        easyBonus;
    return math.max(0.1, s * (1 + factor));
  }

  /// Stability après échec (lapse) en mode review.
  double _stabilityAfterFailure(double d, double s, double r) {
    final newS = weights[11] *
        math.pow(d, -weights[12]) *
        (math.pow(s + 1, weights[13]) - 1) *
        math.exp((1 - r) * weights[14]);
    return math.max(0.1, newS.toDouble());
  }

  /// Stability en learning / relearning (formule simplifiée).
  double _shortTermStability(double s, FsrsRating rating) {
    if (s == 0) return _initialStability(rating);
    // Boost léger pour Good/Easy, neutre Hard, réduction Again
    final factor = switch (rating) {
      FsrsRating.again => 0.5,
      FsrsRating.hard => 1.0,
      FsrsRating.good => 1.5,
      FsrsRating.easy => 2.0,
    };
    return math.max(0.1, s * factor);
  }

  /// Intervalle suivant en jours selon stabilité courante.
  /// I = S * (target^(-1/decay) - 1) / factor
  double _nextInterval(double stability) {
    final raw =
        stability * (math.pow(requestRetention, 1 / _decay) - 1) / _factor;
    return raw.clamp(1.0, maximumInterval.toDouble());
  }

  /// Pour afficher à l'utilisateur l'intervalle qui résulterait de chaque
  /// grade — utile pour mettre les estimations sous chaque bouton.
  Map<FsrsRating, double> previewIntervals(FsrsCard card, DateTime now) {
    return {
      for (final r in FsrsRating.values)
        r: () {
          final next = schedule(card, r, now);
          if (next.dueAt == 0) return 0.0;
          return (next.dueAt - now.millisecondsSinceEpoch) / 86400000.0;
        }(),
    };
  }
}
