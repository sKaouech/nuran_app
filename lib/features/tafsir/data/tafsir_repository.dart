import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tafsir_source.dart';

/// Charge les tafsirs depuis les assets et les met en cache.
/// Chargement lazy : on charge seulement ce qui est demandé.
class TafsirRepository {
  TafsirRepository._();

  final Map<TafsirSource, List<String>> _cache = {};

  /// Récupère le tafsir d'un verset (par globalIndex 1..6236) dans une source.
  Future<String?> tafsirFor({
    required TafsirSource source,
    required int globalIndex,
  }) async {
    final list = await _load(source);
    if (globalIndex < 1 || globalIndex > list.length) return null;
    return list[globalIndex - 1];
  }

  Future<List<String>> _load(TafsirSource source) async {
    final cached = _cache[source];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(source.assetPath);
    final list = (json.decode(raw) as List).cast<String>();
    _cache[source] = list;
    return list;
  }

  /// Pré-charge en background. Utile pour réduire la latence au premier affichage.
  Future<void> preload(TafsirSource source) async {
    if (_cache.containsKey(source)) return;
    await _load(source);
  }
}

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) {
  return TafsirRepository._();
});

/// Source actuellement sélectionnée par l'utilisateur (persistée plus tard).
final selectedTafsirProvider = StateProvider<TafsirSource>((ref) {
  return TafsirSource.muyassarAr;
});
