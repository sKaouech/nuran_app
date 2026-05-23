import 'package:flutter/foundation.dart';

@immutable
class Verse {
  const Verse({
    required this.surahNumber,
    required this.ayahInSurah,
    required this.globalIndex,
    required this.arabicText,
    required this.juz,
    required this.hizbQuarter,
    required this.page,
  });

  /// Numéro de sourate (1-114).
  final int surahNumber;

  /// Numéro du verset DANS la sourate (1..versesCount).
  final int ayahInSurah;

  /// Index global du verset (1..6236).
  final int globalIndex;

  /// Texte arabe Hafs Uthmani.
  final String arabicText;

  /// Juz (1-30).
  final int juz;

  /// Hizb quarter (1-240).
  final int hizbQuarter;

  /// Page Mushaf Madinah (1-604).
  final int page;

  String get reference => '$surahNumber:$ayahInSurah';

  factory Verse.fromJson(Map<String, dynamic> json, int globalIndex) => Verse(
        surahNumber: json['s'] as int,
        ayahInSurah: json['i'] as int,
        globalIndex: globalIndex,
        arabicText: json['t'] as String,
        juz: (json['j'] as num).toInt(),
        hizbQuarter: (json['h'] as num).toInt(),
        page: (json['p'] as num).toInt(),
      );
}
