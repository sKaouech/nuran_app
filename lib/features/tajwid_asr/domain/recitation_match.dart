import 'package:flutter/foundation.dart';

/// Statut d'un mot dans la comparaison récitation vs texte attendu.
enum WordMatchStatus {
  correct, // mot reconnu correctement
  wrong, // mot reconnu mais différent
  missing, // mot non reconnu du tout
}

@immutable
class WordMatch {
  const WordMatch({
    required this.expected,
    required this.recognized,
    required this.status,
  });

  /// Mot attendu (du verset Coran).
  final String expected;

  /// Mot reconnu par l'ASR (peut être null si missing).
  final String? recognized;

  final WordMatchStatus status;
}

@immutable
class RecitationResult {
  const RecitationResult({
    required this.expectedText,
    required this.recognizedText,
    required this.matches,
  });

  final String expectedText;
  final String recognizedText;
  final List<WordMatch> matches;

  /// Nombre de mots corrects.
  int get correctCount =>
      matches.where((m) => m.status == WordMatchStatus.correct).length;

  /// Score 0-100.
  int get scorePercent {
    if (matches.isEmpty) return 0;
    return ((correctCount / matches.length) * 100).round();
  }

  /// Classification qualitative.
  String get gradeLabel {
    final s = scorePercent;
    if (s >= 95) return 'Excellent';
    if (s >= 80) return 'Très bon';
    if (s >= 60) return 'Bon';
    if (s >= 40) return 'À retravailler';
    return 'À recommencer';
  }
}

/// Compare un texte attendu (verset Coran) avec une transcription ASR.
/// Utilise la normalisation arabe (suppression tashkil, unification alif/ya/ta).
class ArabicTextMatcher {
  ArabicTextMatcher._();

  static String normalize(String text) {
    final tashkil = RegExp(r'[ً-ٰٟـ]');
    return text
        .replaceAll(tashkil, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ء', '')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .toLowerCase()
        .trim();
  }

  /// Compare le texte attendu et le texte reconnu en alignant mot-à-mot.
  /// Pour chaque mot attendu, on cherche son équivalent dans la transcription.
  ///
  /// Algo simple type "alignement glouton" : on parcourt les mots attendus
  /// dans l'ordre, et on cherche le prochain mot reconnu qui matche après
  /// le curseur courant.
  static RecitationResult compare({
    required String expected,
    required String recognized,
  }) {
    final expectedWords = expected.trim().split(RegExp(r'\s+'));
    final recognizedWords = recognized.trim().split(RegExp(r'\s+'));

    final matches = <WordMatch>[];
    var recCursor = 0;

    for (final expWord in expectedWords) {
      final expNorm = normalize(expWord);
      if (expNorm.isEmpty) continue;

      // Cherche le mot dans une fenêtre raisonnable après le curseur
      var found = -1;
      final windowEnd =
          (recCursor + 4).clamp(0, recognizedWords.length);
      for (var i = recCursor; i < windowEnd; i++) {
        if (normalize(recognizedWords[i]) == expNorm) {
          found = i;
          break;
        }
      }

      if (found >= 0) {
        matches.add(WordMatch(
          expected: expWord,
          recognized: recognizedWords[found],
          status: WordMatchStatus.correct,
        ));
        recCursor = found + 1;
      } else if (recCursor < recognizedWords.length) {
        // Mot suivant dans l'ASR mais différent → wrong
        matches.add(WordMatch(
          expected: expWord,
          recognized: recognizedWords[recCursor],
          status: WordMatchStatus.wrong,
        ));
        recCursor++;
      } else {
        // Plus rien à matcher → missing
        matches.add(WordMatch(
          expected: expWord,
          recognized: null,
          status: WordMatchStatus.missing,
        ));
      }
    }

    return RecitationResult(
      expectedText: expected,
      recognizedText: recognized,
      matches: matches,
    );
  }
}
