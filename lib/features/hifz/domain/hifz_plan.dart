import 'package:flutter/foundation.dart';

enum HifzGoal { surah, juz, fullQuran }

extension HifzGoalX on HifzGoal {
  String get storageKey => name;
  static HifzGoal fromStorage(String? value) {
    if (value == null) return HifzGoal.surah;
    return HifzGoal.values.firstWhere(
      (g) => g.name == value,
      orElse: () => HifzGoal.surah,
    );
  }
}

/// Plan de mémorisation personnalisé de l'utilisateur.
@immutable
class HifzPlan {
  const HifzPlan({
    required this.goal,
    required this.startSurah,
    required this.versesPerDay,
    required this.startedAt,
    this.targetSurahOrJuz,
  });

  /// Type d'objectif (sourate, juz, ou Coran complet).
  final HifzGoal goal;

  /// Sourate de départ (1..114).
  final int startSurah;

  /// Sourate ou juz cible quand goal = surah ou juz.
  /// Pour fullQuran, ignoré.
  final int? targetSurahOrJuz;

  /// Cadence (1 / 3 / 5 / 10 versets / jour).
  final int versesPerDay;

  /// Date de début (timestamp millis).
  final int startedAt;

  Map<String, dynamic> toJson() => {
        'goal': goal.storageKey,
        'startSurah': startSurah,
        'target': targetSurahOrJuz,
        'versesPerDay': versesPerDay,
        'startedAt': startedAt,
      };

  factory HifzPlan.fromJson(Map<String, dynamic> json) => HifzPlan(
        goal: HifzGoalX.fromStorage(json['goal'] as String?),
        startSurah: json['startSurah'] as int,
        targetSurahOrJuz: json['target'] as int?,
        versesPerDay: json['versesPerDay'] as int,
        startedAt: json['startedAt'] as int,
      );
}
