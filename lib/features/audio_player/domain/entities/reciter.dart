import 'package:flutter/foundation.dart';

@immutable
class Reciter {
  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.everyayahPath,
    required this.bitrate,
    this.isSlow = false,
    this.isPremium = false,
  });

  /// Identifiant unique stable (= dossier everyayah).
  final String id;
  final String nameArabic;
  final String nameEnglish;

  /// Chemin everyayah.com (ex: "Husary_128kbps").
  final String everyayahPath;

  /// Bitrate (info utilisateur).
  final int bitrate;

  /// Récitateur lent — mode "muallim" pour apprentissage.
  final bool isSlow;
  final bool isPremium;

  /// Construit l'URL audio pour un verset donné.
  /// Format everyayah : 3 chiffres sourate + 3 chiffres verset.
  String audioUrlFor({required int surah, required int ayah}) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$everyayahPath/$s$a.mp3';
  }
}
