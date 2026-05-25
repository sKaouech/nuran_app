import 'package:flutter/foundation.dart';

import 'phonetic_analysis.dart';

/// Statut d'un mot dans la comparaison récitation vs texte attendu.
enum WordMatchStatus {
  /// Match parfait (après normalisation tashkil).
  correct,

  /// Match phonétique : substitution de lettres proches (ت/ط, ذ/ز/ظ, ...)
  /// ou faute Tajwid détectée (madd raccourci, ghunnah omise, qalqalah manquée).
  /// Niveau 2 : on ne pénalise pas autant qu'une erreur franche.
  phonetic,

  /// Mot reconnu mais franchement différent.
  wrong,

  /// Mot non reconnu du tout.
  missing,
}

@immutable
class WordMatch {
  const WordMatch({
    required this.expected,
    required this.recognized,
    required this.status,
    this.analysis,
  });

  /// Mot attendu (du verset Coran, avec diacritiques).
  final String expected;

  /// Mot reconnu par l'ASR (peut être null si missing).
  final String? recognized;

  final WordMatchStatus status;

  /// Détail de l'analyse phonétique niveau 2 (null pour `missing`).
  final PhoneticWordAnalysis? analysis;

  /// Liste des fautes Tajwid détectées (raccourci vers analysis.faults).
  List<TajwidFault> get faults => analysis?.faults ?? const [];
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

  /// Nombre de mots parfaits.
  int get correctCount =>
      matches.where((m) => m.status == WordMatchStatus.correct).length;

  /// Nombre de mots phonétiquement proches (substitutions / fautes Tajwid mineures).
  int get phoneticCount =>
      matches.where((m) => m.status == WordMatchStatus.phonetic).length;

  /// Nombre de mots franchement incorrects.
  int get wrongCount =>
      matches.where((m) => m.status == WordMatchStatus.wrong).length;

  /// Nombre de mots manquants.
  int get missingCount =>
      matches.where((m) => m.status == WordMatchStatus.missing).length;

  /// Score 0-100 pondéré : un mot correct vaut 1, phonétique 0.5, wrong/missing 0.
  ///
  /// Cette pondération est plus indulgente que le niveau 1 et reflète mieux
  /// la réalité d'un apprentissage : une substitution ت/ط n'est pas équivalente
  /// à une omission complète.
  int get scorePercent {
    if (matches.isEmpty) return 0;
    final weighted = correctCount + (phoneticCount * 0.5);
    return ((weighted / matches.length) * 100).round();
  }

  /// Toutes les fautes Tajwid uniques détectées sur l'ensemble du verset.
  Set<TajwidFault> get uniqueFaults {
    final s = <TajwidFault>{};
    for (final m in matches) {
      s.addAll(m.faults);
    }
    return s;
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
///
/// **Niveau 2** : utilise [PhoneticAnalyzer] pour distinguer les substitutions
/// phonétiques (lettres proches confondues par l'ASR) des erreurs franches,
/// et détecter les fautes Tajwid spécifiques.
class ArabicTextMatcher {
  ArabicTextMatcher._();

  /// Seuil de similarité Levenshtein normalisée en dessous duquel on considère
  /// que c'est un mot franchement différent.
  static const _wrongThreshold = 0.55;

  /// Seuil au-dessus duquel on considère que c'est un match exact (même après
  /// normalisation phonétique stricte).
  static const _correctThreshold = 0.95;

  /// Normalisation stricte exposée pour compatibilité avec l'API existante.
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

  /// Compare expected/recognized via alignement glouton + analyse phonétique
  /// niveau 2 (substitutions, fautes Tajwid).
  static RecitationResult compare({
    required String expected,
    required String recognized,
  }) {
    final expectedWords =
        expected.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final recognizedWords = recognized
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final matches = <WordMatch>[];
    var recCursor = 0;

    for (final expWord in expectedWords) {
      final expNorm = normalize(expWord);
      if (expNorm.isEmpty) continue;

      // Recherche dans une fenêtre raisonnable après le curseur.
      // Le matching utilise la forme phonétique normalisée pour être tolérant
      // aux substitutions de lettres proches.
      final expPhon = PhoneticAnalyzer.phoneticForm(expWord);
      var bestMatch = -1;
      var bestSim = 0.0;
      final windowEnd = (recCursor + 4).clamp(0, recognizedWords.length);
      for (var i = recCursor; i < windowEnd; i++) {
        final recPhon = PhoneticAnalyzer.phoneticForm(recognizedWords[i]);
        final sim = PhoneticAnalyzer.similarity(expPhon, recPhon);
        if (sim > bestSim) {
          bestSim = sim;
          bestMatch = i;
        }
      }

      if (bestMatch >= 0 && bestSim >= _wrongThreshold) {
        final recognizedWord = recognizedWords[bestMatch];
        final analysis = PhoneticAnalyzer.analyzeWord(
          expected: expWord,
          recognized: recognizedWord,
        );
        final WordMatchStatus status;
        if (bestSim >= _correctThreshold && analysis.faults.isEmpty) {
          status = WordMatchStatus.correct;
        } else {
          // Match phonétique : soit similarité < 0.95, soit faute Tajwid détectée.
          status = WordMatchStatus.phonetic;
        }
        matches.add(WordMatch(
          expected: expWord,
          recognized: recognizedWord,
          status: status,
          analysis: analysis,
        ));
        recCursor = bestMatch + 1;
      } else if (recCursor < recognizedWords.length) {
        // Aucun match phonétique acceptable dans la fenêtre → mot franchement
        // différent. On consomme tout de même le mot suivant pour ne pas
        // bloquer le curseur.
        final recognizedWord = recognizedWords[recCursor];
        final analysis = PhoneticAnalyzer.analyzeWord(
          expected: expWord,
          recognized: recognizedWord,
        );
        matches.add(WordMatch(
          expected: expWord,
          recognized: recognizedWord,
          status: WordMatchStatus.wrong,
          analysis: analysis,
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
