/// Analyse phonétique niveau 2 — comparaison fine entre un mot attendu et
/// un mot reconnu par l'ASR.
///
/// Au-delà du simple match exact (niveau 1), ce module gère :
/// 1. **Lettres confondables phonétiquement** : l'ASR confond souvent des paires
///    de lettres arabes proches (ت/ط, ذ/ز/ظ, ح/ه, ص/س, ق/ك, د/ض). On considère
///    ces substitutions comme "proches" plutôt que comme une erreur franche.
/// 2. **Distance de Levenshtein normalisée** : pour mesurer la similarité entre
///    deux mots après normalisation tashkil + équivalences phonétiques.
/// 3. **Détection de fautes Tajwid spécifiques** : madd raccourci, ghunnah
///    omise, qalqalah manquée — par comparaison de la structure du mot attendu
///    (avec diacritiques) et du mot reconnu (sans).
library;

import 'package:flutter/foundation.dart';

/// Classes d'équivalence phonétique arabes. Deux lettres dans la même classe
/// sont considérées comme phonétiquement proches du point de vue de l'ASR.
///
/// Source : confusions communes observées sur Apple SFSpeechRecognizer et
/// Google STT pour l'arabe (variation dialectale + qualité micro).
const Map<String, String> _phoneticClasses = {
  // Dentales emphatiques / non-emphatiques
  'ت': 't', 'ط': 't',
  // Sifflantes (z-z̧-ð)
  'ذ': 'z', 'ز': 'z', 'ظ': 'z',
  // h aspiré vs gutural
  'ح': 'h', 'ه': 'h', 'ة': 'h',
  // s simple vs emphatique
  'ص': 's', 'س': 's', 'ث': 's',
  // k uvulaire vs vélaire
  'ق': 'k', 'ك': 'k',
  // d simple vs emphatique
  'د': 'd', 'ض': 'd',
  // Glottal stop variants (déjà gérés dans normalize, on garde par sécurité)
  'ع': 'a', 'ء': 'a',
};

/// Diagnostic Tajwid d'un mot — quelle règle a été potentiellement manquée.
enum TajwidFault {
  /// Madd (allongement) raccourci dans la prononciation.
  maddShortened('Madd raccourci', 'L\'allongement n\'a pas été tenu assez longtemps.'),

  /// Ghunnah (nasalité ن/م مشدّد) omise.
  ghunnahMissed('Ghunnah omise', 'La nasalité du ن ou م avec shadda n\'a pas été perçue.'),

  /// Qalqalah (rebond ق ط ب ج د en sukun) non marquée.
  qalqalahMissed('Qalqalah absente', 'Le rebond des lettres ق ط ب ج د en sukun manque.'),

  /// Substitution d'une lettre par une lettre phonétiquement proche
  /// (ex: ط prononcé comme ت).
  phoneticSubstitution('Lettre confondue', 'Une lettre a été prononcée de façon trop proche d\'une lettre similaire.');

  const TajwidFault(this.label, this.description);
  final String label;
  final String description;
}

/// Résultat d'analyse phonétique pour un mot.
@immutable
class PhoneticWordAnalysis {
  const PhoneticWordAnalysis({
    required this.expected,
    required this.recognized,
    required this.similarity,
    required this.faults,
  });

  final String expected;
  final String? recognized;

  /// Similarité 0.0 → 1.0 (1 = identiques après normalisation, 0 = totalement différents).
  final double similarity;

  /// Fautes Tajwid détectées (peut être vide).
  final List<TajwidFault> faults;

  /// True si le mot est correct (similarité ≥ 0.95 et aucune faute).
  bool get isPerfect => similarity >= 0.95 && faults.isEmpty;

  /// True si le mot est phonétiquement très proche (substitution mineure).
  bool get isClose => similarity >= 0.70 && similarity < 0.95;

  /// True si le mot est franchement différent ou manquant.
  bool get isWrong => similarity < 0.70;
}

class PhoneticAnalyzer {
  PhoneticAnalyzer._();

  // Diacritiques arabes
  static const _shadda = 'ّ';
  static const _sukoon = 'ْ';
  static const _fatha = 'َ';
  static const _damma = 'ُ';
  static const _kasra = 'ِ';
  static const _qalqalahLetters = {'ق', 'ط', 'ب', 'ج', 'د'};

  /// Normalisation phonétique : enlève tashkil + remplace chaque lettre par
  /// sa classe d'équivalence phonétique. Deux mots qui ne différent que par
  /// ت vs ط auront la même forme phonétique.
  static String phoneticForm(String word) {
    final tashkil = RegExp(r'[ً-ٰٟـ]');
    final base = word
        .replaceAll(tashkil, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .toLowerCase()
        .trim();
    final buf = StringBuffer();
    for (final r in base.runes) {
      final ch = String.fromCharCode(r);
      buf.write(_phoneticClasses[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Distance de Levenshtein entre deux chaînes (itératif O(n×m)).
  @visibleForTesting
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final m = a.length;
    final n = b.length;
    // Optimisation mémoire : on garde deux lignes seulement.
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        var best = del < ins ? del : ins;
        if (sub < best) best = sub;
        curr[j] = best;
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }

  /// Similarité Levenshtein normalisée 0..1.
  static double similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - (levenshtein(a, b) / maxLen);
  }

  /// Analyse phonétique complète d'un mot attendu vs reconnu.
  ///
  /// [expected] doit contenir les diacritiques Hafs (utilisés pour la
  /// détection des fautes Tajwid). [recognized] peut être null (mot non
  /// reconnu) ou sans tashkil (sortie ASR).
  static PhoneticWordAnalysis analyzeWord({
    required String expected,
    required String? recognized,
  }) {
    if (recognized == null || recognized.trim().isEmpty) {
      return PhoneticWordAnalysis(
        expected: expected,
        recognized: null,
        similarity: 0.0,
        faults: const [],
      );
    }

    final expPhon = phoneticForm(expected);
    final recPhon = phoneticForm(recognized);
    final sim = similarity(expPhon, recPhon);

    // Détection des fautes Tajwid — uniquement si on a un mot reconnu plausible.
    final faults = <TajwidFault>[];

    // 1. Substitution phonétique : la forme normalisée stricte (sans classes)
    //    diffère, mais la forme phonétique correspond → l'ASR a confondu deux
    //    lettres de la même classe.
    final expStrict = _strictNormalize(expected);
    final recStrict = _strictNormalize(recognized);
    if (expStrict != recStrict && expPhon == recPhon) {
      faults.add(TajwidFault.phoneticSubstitution);
    }

    // 2. Madd raccourci : le mot attendu contient une voyelle longue suivie
    //    d'une lettre de prolongation (ا/و/ي), mais le mot reconnu est plus
    //    court d'au moins une lettre par rapport à l'attendu.
    if (_hasMaddPattern(expected) &&
        recStrict.length < expStrict.length &&
        sim >= 0.5) {
      faults.add(TajwidFault.maddShortened);
    }

    // 3. Ghunnah omise : on construit une forme "attendue avec doublement"
    //    (la shadda implique une articulation doublée du ن/م). Si le mot
    //    reconnu ne contient pas ce doublement, on signale.
    if (_hasGhunnah(expected)) {
      final expDoubled = _expandShadda(expStrict, expected);
      // Si expansion réelle ET le mot reconnu n'a pas la double lettre.
      if (expDoubled != expStrict && recStrict != expDoubled && sim >= 0.5) {
        faults.add(TajwidFault.ghunnahMissed);
      }
    }

    // 4. Qalqalah : le mot attendu contient une lettre qalqalah en sukun. Si
    //    le reconnu est globalement proche mais pas parfait, on signale.
    if (_hasQalqalah(expected) && sim < 0.95 && sim >= 0.6) {
      faults.add(TajwidFault.qalqalahMissed);
    }

    return PhoneticWordAnalysis(
      expected: expected,
      recognized: recognized,
      similarity: sim,
      faults: faults,
    );
  }

  /// Normalisation stricte : tashkil + alif unifié, mais SANS classes
  /// d'équivalence phonétique. Sert à détecter les substitutions phonétiques.
  static String _strictNormalize(String word) {
    final tashkil = RegExp(r'[ً-ٰٟـ]');
    return word
        .replaceAll(tashkil, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .toLowerCase()
        .trim();
  }

  /// Détecte la présence d'un motif de madd dans le mot.
  /// Madd = fatha+ا, damma+و, kasra+ي (lettres de prolongation).
  static bool _hasMaddPattern(String word) {
    return word.contains('$_fathaا') ||
        word.contains('$_dammaو') ||
        word.contains('$_kasraي');
  }

  /// Détecte ن ou م porteur de shadda (= ghunnah). Le mushaf Hafs Uthmani
  /// place souvent une voyelle entre la lettre et la shadda (ex: نَّ = ن + fatha
  /// + shadda), donc on tolère un diacritique intermédiaire.
  static bool _hasGhunnah(String word) {
    return RegExp(r'[نم][ً-ٟ]?ّ').hasMatch(word);
  }

  /// Construit une forme strict-normalisée où chaque ن/م porteur de shadda
  /// est doublé (le shadda dans le mushaf = articulation deux fois). Sert à
  /// détecter une ghunnah omise dans l'ASR.
  static String _expandShadda(String strictForm, String original) {
    // On parcourt l'original char par char et on double les ن/م après shadda.
    // Mais comme strictForm a déjà perdu les diacritiques, on doit reconstruire
    // à partir de l'original.
    final buf = StringBuffer();
    final chars = original.runes.map(String.fromCharCode).toList();
    for (var i = 0; i < chars.length; i++) {
      final ch = chars[i];
      // On ne garde que les lettres (pas les diacritiques) dans le buffer.
      if (_isDiacriticChar(ch)) {
        // Si c'est une shadda, on remonte à travers les diacritiques pour
        // retrouver la lettre porteuse et la doubler si c'est ن ou م.
        if (ch == _shadda) {
          for (var j = i - 1; j >= 0; j--) {
            final prev = chars[j];
            if (_isDiacriticChar(prev)) continue;
            if (prev == 'ن' || prev == 'م') {
              buf.write(prev);
            }
            break;
          }
        }
        continue;
      }
      // Remplacement alif unifié (cohérent avec _strictNormalize).
      final mapped = switch (ch) {
        'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
        'ى' => 'ي',
        _ => ch,
      };
      buf.write(mapped);
    }
    return buf.toString().toLowerCase().trim();
  }

  static bool _isDiacriticChar(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return code >= 0x064B && code <= 0x065F;
  }

  /// Détecte une lettre qalqalah en sukun dans le mot.
  static bool _hasQalqalah(String word) {
    for (final letter in _qalqalahLetters) {
      if (word.contains('$letter$_sukoon')) return true;
    }
    return false;
  }
}
