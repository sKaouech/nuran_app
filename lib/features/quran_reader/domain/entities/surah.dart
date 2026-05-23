import 'package:flutter/foundation.dart';

@immutable
class Surah {
  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameEnglishTranslation,
    required this.revelationType,
    required this.versesCount,
  });

  /// Numéro de sourate (1-114).
  final int number;

  /// Nom arabe (سُورَةُ ٱلْفَاتِحَةِ).
  final String nameArabic;

  /// Nom translittéré (Al-Faatiha).
  final String nameEnglish;

  /// Traduction du nom (The Opening).
  final String nameEnglishTranslation;

  /// "Meccan" ou "Medinan".
  final String revelationType;

  /// Nombre de versets.
  final int versesCount;

  bool get isMeccan => revelationType == 'Meccan';

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        number: json['n'] as int,
        nameArabic: json['name_ar'] as String,
        nameEnglish: json['name_en'] as String,
        nameEnglishTranslation: json['name_en_tr'] as String,
        revelationType: json['type'] as String,
        versesCount: json['count'] as int,
      );
}
