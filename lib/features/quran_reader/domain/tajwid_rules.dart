import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Catégories de règles tajwid colorées sur le mushaf.
///
/// **Niveau V1 — heuristique** : détection automatique via regex sur le texte
/// Hafs Uthmani, sans annotations manuelles. Ne couvre pas toutes les
/// subtilités d'un mushaf tajwid imprimé, mais donne une indication visuelle
/// utile pour l'apprentissage.
enum TajwidRule {
  /// Madd : allongement (ا، و، ي de prolongation après voyelle courte).
  /// Couleur traditionnelle : vert.
  madd(Color(0xFF2E7D5F), 'Madd', 'Allongement'),

  /// Ghunnah : nasalité (ن، م avec shadda).
  /// Couleur traditionnelle : orange/rouge.
  ghunnah(Color(0xFFD97706), 'Ghunnah', 'Nasalité'),

  /// Qalqalah : rebond (ق ط ب ج د en sukoon).
  /// Couleur traditionnelle : bleu/violet.
  qalqalah(Color(0xFF6B46C1), 'Qalqalah', 'Rebond');

  const TajwidRule(this.color, this.label, this.description);
  final Color color;
  final String label;
  final String description;
}

/// Segment de texte avec sa règle tajwid (ou null si neutre).
class TajwidSegment {
  const TajwidSegment(this.text, this.rule);
  final String text;
  final TajwidRule? rule;
}

/// Détecte les règles tajwid simples dans un verset arabe Hafs Uthmani.
///
/// Limitations V1 :
/// - Ne traite pas tous les cas d'idgham, ikhfa, iqlab (règles de noon sakinah)
/// - Madd : seulement la détection basique des lettres prolongatrices
/// - Pas de distinction madd lazim / madd `arid / madd muttasil
class TajwidAnalyzer {
  TajwidAnalyzer._();

  // Caractères arabes pertinents
  static const _shadda = 'ّ';
  static const _sukoon = 'ْ';
  static const _fatha = 'َ';
  static const _damma = 'ُ';
  static const _kasra = 'ِ';

  static const _alif = 'ا';
  static const _waw = 'و';
  static const _ya = 'ي';
  static const _alifMaqsura = 'ى';

  static const _nun = 'ن';
  static const _mim = 'م';

  // Lettres de qalqalah : ق ط ب ج د
  static const _qalqalahLetters = {'ق', 'ط', 'ب', 'ج', 'د'};

  /// Découpe le texte en segments annotés selon les règles tajwid détectées.
  ///
  /// Retourne une liste de [TajwidSegment]. Les segments contigus de même
  /// catégorie sont fusionnés pour limiter le nombre de spans.
  static List<TajwidSegment> analyze(String text) {
    final raw = <_RawAnnotated>[];
    final chars = text.runes.map(String.fromCharCode).toList();

    for (var i = 0; i < chars.length; i++) {
      final ch = chars[i];
      final prev = i > 0 ? chars[i - 1] : '';
      final next = i + 1 < chars.length ? chars[i + 1] : '';

      TajwidRule? rule;

      // GHUNNAH : ن ou م suivi de shadda
      if ((ch == _nun || ch == _mim) && next == _shadda) {
        rule = TajwidRule.ghunnah;
      }
      // On continue à colorier le shadda lui-même
      else if (ch == _shadda && (prev == _nun || prev == _mim)) {
        rule = TajwidRule.ghunnah;
      }

      // QALQALAH : lettre qalqalah en sukoon (le caractère sukoon est mis APRÈS)
      else if (_qalqalahLetters.contains(ch) && next == _sukoon) {
        rule = TajwidRule.qalqalah;
      } else if (ch == _sukoon && _qalqalahLetters.contains(prev)) {
        rule = TajwidRule.qalqalah;
      }

      // MADD : alif/waw/ya de prolongation
      // Heuristique : ا précédé d'une fatha, و précédé d'une damma, ي précédé d'une kasra
      else if (ch == _alif || ch == _alifMaqsura) {
        // Cherche en arrière une fatha (en sautant les diacritiques)
        if (_lastVoyelle(chars, i) == _fatha) {
          rule = TajwidRule.madd;
        }
      } else if (ch == _waw) {
        if (_lastVoyelle(chars, i) == _damma && next != _shadda) {
          rule = TajwidRule.madd;
        }
      } else if (ch == _ya) {
        if (_lastVoyelle(chars, i) == _kasra && next != _shadda) {
          rule = TajwidRule.madd;
        }
      }

      raw.add(_RawAnnotated(ch, rule));
    }

    // Fusion des segments contigus de même règle
    final result = <TajwidSegment>[];
    var bufText = StringBuffer();
    TajwidRule? bufRule;
    for (final a in raw) {
      if (a.rule == bufRule) {
        bufText.write(a.ch);
      } else {
        if (bufText.isNotEmpty) {
          result.add(TajwidSegment(bufText.toString(), bufRule));
        }
        bufText = StringBuffer(a.ch);
        bufRule = a.rule;
      }
    }
    if (bufText.isNotEmpty) {
      result.add(TajwidSegment(bufText.toString(), bufRule));
    }
    return result;
  }

  /// Cherche la dernière voyelle courte (fatha/damma/kasra) avant la position
  /// donnée, en remontant à travers les diacritiques.
  static String? _lastVoyelle(List<String> chars, int from) {
    for (var j = from - 1; j >= 0 && j > from - 4; j--) {
      final c = chars[j];
      if (c == _fatha || c == _damma || c == _kasra) return c;
      // Si on tombe sur un caractère consonne (non-diacritique), on arrête
      if (!_isDiacritic(c)) return null;
    }
    return null;
  }

  static bool _isDiacritic(String c) {
    final code = c.codeUnitAt(0);
    return code >= 0x064B && code <= 0x065F;
  }
}

class _RawAnnotated {
  const _RawAnnotated(this.ch, this.rule);
  final String ch;
  final TajwidRule? rule;
}

/// Réutilisé par d'autres widgets : la liste des couleurs pour la légende.
const tajwidColors = [
  (color: AppColors.success, rule: TajwidRule.madd),
  (color: AppColors.warning, rule: TajwidRule.ghunnah),
];
