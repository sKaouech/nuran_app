import 'package:flutter_test/flutter_test.dart';
import 'package:nuran/features/murajaa/domain/fsrs_algorithm.dart';
import 'package:nuran/features/murajaa/domain/fsrs_card.dart';

void main() {
  final algo = FsrsAlgorithm();
  final now = DateTime(2026, 5, 24, 10, 0);

  group('FsrsAlgorithm — first review', () {
    test('Again on new card → stays in learning, due in 0 day', () {
      final card = FsrsCard.newFor(1);
      final result = algo.schedule(card, FsrsRating.again, now);

      expect(result.state, FsrsState.learning);
      expect(result.reps, 1);
      expect(result.lapses, 0);
      expect(result.stability, greaterThan(0));
      expect(result.lastReviewAt, now.millisecondsSinceEpoch);
    });

    test('Good on new card → goes to review with future due date', () {
      final card = FsrsCard.newFor(1);
      final result = algo.schedule(card, FsrsRating.good, now);

      expect(result.state, FsrsState.review);
      expect(result.reps, 1);
      expect(result.dueAt, greaterThan(now.millisecondsSinceEpoch));
      // Initial good → at least a day later
      final intervalDays =
          (result.dueAt - now.millisecondsSinceEpoch) / 86400000.0;
      expect(intervalDays, greaterThanOrEqualTo(1));
    });

    test('Easy gives higher initial stability than Good', () {
      final cardE = algo.schedule(
        FsrsCard.newFor(1),
        FsrsRating.easy,
        now,
      );
      final cardG = algo.schedule(
        FsrsCard.newFor(2),
        FsrsRating.good,
        now,
      );
      expect(cardE.stability, greaterThan(cardG.stability));
    });
  });

  group('FsrsAlgorithm — review state', () {
    test('Again on review card → lapse, back to relearning', () {
      var card = FsrsCard.newFor(1);
      card = algo.schedule(card, FsrsRating.good, now);
      // Simulate elapsed time = 7 days
      final later = now.add(const Duration(days: 7));
      card = algo.schedule(card, FsrsRating.again, later);

      expect(card.state, FsrsState.relearning);
      expect(card.lapses, 1);
    });

    test('Good then Good increases stability over time', () {
      var card = FsrsCard.newFor(1);
      card = algo.schedule(card, FsrsRating.good, now);
      final s1 = card.stability;

      // 5 days later, rate Good again
      final later = now.add(const Duration(days: 5));
      card = algo.schedule(card, FsrsRating.good, later);

      expect(card.stability, greaterThan(s1));
      expect(card.state, FsrsState.review);
    });

    test('Easy gives bigger stability boost than Good', () {
      var cardE = FsrsCard.newFor(1);
      cardE = algo.schedule(cardE, FsrsRating.good, now);
      var cardG = FsrsCard.newFor(2);
      cardG = algo.schedule(cardG, FsrsRating.good, now);

      final later = now.add(const Duration(days: 3));
      cardE = algo.schedule(cardE, FsrsRating.easy, later);
      cardG = algo.schedule(cardG, FsrsRating.good, later);

      expect(cardE.stability, greaterThan(cardG.stability));
    });
  });

  group('FsrsCard — retrievability', () {
    test('Retrievability = 1.0 just after review', () {
      var card = FsrsCard.newFor(1);
      card = algo.schedule(card, FsrsRating.good, now);
      // 1 millisecond later
      final justAfter = DateTime.fromMillisecondsSinceEpoch(
        card.lastReviewAt + 1,
      );
      expect(card.retrievabilityAt(justAfter), closeTo(1.0, 0.01));
    });

    test('Retrievability decreases with elapsed time', () {
      var card = FsrsCard.newFor(1);
      card = algo.schedule(card, FsrsRating.good, now);
      final r1 = card.retrievabilityAt(now.add(const Duration(days: 1)));
      final r2 = card.retrievabilityAt(now.add(const Duration(days: 10)));
      expect(r2, lessThan(r1));
    });

    test('New card (never reviewed) has retrievability 0', () {
      final card = FsrsCard.newFor(1);
      expect(card.retrievabilityAt(now), 0);
    });
  });

  group('FsrsAlgorithm — previewIntervals', () {
    test('Returns 4 intervals (one per rating)', () {
      var card = FsrsCard.newFor(1);
      card = algo.schedule(card, FsrsRating.good, now);
      final preview = algo.previewIntervals(card, now);
      expect(preview.keys.length, 4);
      expect(preview[FsrsRating.again], isNotNull);
      expect(preview[FsrsRating.easy],
          greaterThanOrEqualTo(preview[FsrsRating.good]!));
    });

    test('Easy interval > Good interval > Hard interval', () {
      var card = FsrsCard.newFor(1);
      card = algo.schedule(card, FsrsRating.good, now);
      final later = now.add(const Duration(days: 3));
      final preview = algo.previewIntervals(card, later);

      expect(preview[FsrsRating.easy], greaterThan(preview[FsrsRating.good]!));
      expect(preview[FsrsRating.good], greaterThan(preview[FsrsRating.hard]!));
    });
  });

  group('FsrsCard — JSON round-trip', () {
    test('toJson then fromJson preserves all fields', () {
      var card = FsrsCard.newFor(42);
      card = algo.schedule(card, FsrsRating.hard, now);
      final json = card.toJson();
      final restored = FsrsCard.fromJson(json);

      expect(restored.verseGlobalIndex, card.verseGlobalIndex);
      expect(restored.stability, card.stability);
      expect(restored.difficulty, card.difficulty);
      expect(restored.dueAt, card.dueAt);
      expect(restored.lastReviewAt, card.lastReviewAt);
      expect(restored.state, card.state);
      expect(restored.reps, card.reps);
      expect(restored.lapses, card.lapses);
    });
  });
}
