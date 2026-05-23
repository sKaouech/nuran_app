import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/surah.dart';
import '../domain/entities/verse.dart';

/// Charge le Coran depuis les assets JSON et fournit un accès en mémoire.
/// Le Coran est immuable : on le charge une fois au démarrage, ensuite tout
/// est servi depuis la RAM (très rapide, ~5 MB).
class QuranRepository {
  QuranRepository._({
    required this.surahs,
    required this.verses,
    required this.translationsByLang,
  });

  final List<Surah> surahs;

  /// Tous les versets, ordonnés par globalIndex (1..6236).
  final List<Verse> verses;

  /// Map langue → liste des 6236 traductions (index = globalIndex - 1).
  final Map<String, List<String>> translationsByLang;

  static Future<QuranRepository> load() async {
    final surahsRaw = await rootBundle.loadString('assets/data/surahs.json');
    final versesRaw =
        await rootBundle.loadString('assets/data/verses_ar_uthmani.json');
    final frRaw = await rootBundle
        .loadString('assets/data/translation_fr_hamidullah.json');
    final enRaw =
        await rootBundle.loadString('assets/data/translation_en_sahih.json');

    final surahs = (json.decode(surahsRaw) as List)
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final versesJson = json.decode(versesRaw) as List;
    final verses = <Verse>[];
    for (var i = 0; i < versesJson.length; i++) {
      verses.add(Verse.fromJson(versesJson[i] as Map<String, dynamic>, i + 1));
    }

    return QuranRepository._(
      surahs: surahs,
      verses: verses,
      translationsByLang: {
        'fr': (json.decode(frRaw) as List).cast<String>(),
        'en': (json.decode(enRaw) as List).cast<String>(),
      },
    );
  }

  Surah surahByNumber(int number) =>
      surahs.firstWhere((s) => s.number == number);

  /// Versets d'une sourate donnée.
  List<Verse> versesOfSurah(int surahNumber) =>
      verses.where((v) => v.surahNumber == surahNumber).toList(growable: false);

  /// Traduction d'un verset dans une langue.
  String? translationOf(Verse verse, String languageCode) {
    final list = translationsByLang[languageCode];
    if (list == null) return null;
    return list[verse.globalIndex - 1];
  }

  /// Versets d'une page Mushaf Madinah (1..604).
  List<Verse> versesOfPage(int page) =>
      verses.where((v) => v.page == page).toList(growable: false);

  /// Recherche full-text dans le Coran. Insensible à la casse, normalise les
  /// diacritiques arabes (tashkil) pour matcher "الله" même si l'utilisateur
  /// tape sans voyelles.
  ///
  /// Cherche dans : texte arabe (normalisé) + traductions disponibles.
  /// Limite par défaut : 100 résultats pour rester rapide.
  List<SearchResult> search(String query, {int limit = 100}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final qNorm = _normalize(q);
    if (qNorm.isEmpty) return const [];

    final results = <SearchResult>[];

    for (final verse in verses) {
      // Arabe (avec normalisation)
      if (_normalize(verse.arabicText).contains(qNorm)) {
        results.add(SearchResult(verse: verse, matchedLang: 'ar'));
        if (results.length >= limit) break;
        continue;
      }
      // Traductions (insensible à la casse simple)
      bool matched = false;
      for (final entry in translationsByLang.entries) {
        final tr = entry.value[verse.globalIndex - 1].toLowerCase();
        if (tr.contains(q.toLowerCase())) {
          results.add(SearchResult(verse: verse, matchedLang: entry.key));
          matched = true;
          break;
        }
      }
      if (matched && results.length >= limit) break;
    }

    return results;
  }

  /// Normalise un texte arabe pour la recherche :
  /// - Supprime tashkil (fatha, kasra, damma, sukun, shadda, tanwin)
  /// - Supprime tatweel (ـ)
  /// - Unifie alif (أإآ → ا)
  /// - Unifie ya / alif maqsura (ى → ي)
  /// - Supprime hamza (ء)
  static String _normalize(String text) {
    final tashkil = RegExp(r'[ً-ٰٟـ]');
    return text
        .replaceAll(tashkil, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ء', '')
        .toLowerCase();
  }
}

class SearchResult {
  const SearchResult({required this.verse, required this.matchedLang});
  final Verse verse;
  final String matchedLang;
}

/// Provider Riverpod chargeant le Coran de manière lazy (et une seule fois).
final quranRepositoryProvider = FutureProvider<QuranRepository>((ref) {
  return QuranRepository.load();
});
