import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';
import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../domain/hifz_plan.dart';
import '../../domain/memorization_status.dart';
import 'memorization_provider.dart';

const _kKey = 'hifz_plan_v1';

class HifzPlanNotifier extends StateNotifier<HifzPlan?> {
  HifzPlanNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static HifzPlan? _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null) return null;
    try {
      return HifzPlan.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setPlan(HifzPlan plan) async {
    state = plan;
    await _prefs.setString(_kKey, json.encode(plan.toJson()));
  }

  Future<void> clear() async {
    state = null;
    await _prefs.remove(_kKey);
  }
}

final hifzPlanProvider =
    StateNotifierProvider<HifzPlanNotifier, HifzPlan?>((ref) {
  return HifzPlanNotifier(ref.watch(sharedPreferencesProvider));
});

/// Calcule la file du jour : les N prochains versets à mémoriser selon le plan,
/// en sautant ceux déjà marqués comme "memorized".
final todayPlanVersesProvider = Provider<List<Verse>>((ref) {
  final plan = ref.watch(hifzPlanProvider);
  final memo = ref.watch(memorizationProvider);
  final asyncRepo = ref.watch(quranRepositoryProvider);
  final repo = asyncRepo.value;
  if (plan == null || repo == null) return const [];

  // Range cible
  final all = repo.verses;
  final from = all.indexWhere((v) => v.surahNumber == plan.startSurah);
  if (from < 0) return const [];

  int? upToExclusive;
  switch (plan.goal) {
    case HifzGoal.surah:
      final target = plan.targetSurahOrJuz ?? plan.startSurah;
      // jusqu'à la fin de la sourate target (inclus)
      final lastIndex = all.lastIndexWhere((v) => v.surahNumber == target);
      if (lastIndex >= 0) upToExclusive = lastIndex + 1;
      break;
    case HifzGoal.juz:
      final target = plan.targetSurahOrJuz ?? all[from].juz;
      final lastIndex = all.lastIndexWhere((v) => v.juz == target);
      if (lastIndex >= 0) upToExclusive = lastIndex + 1;
      break;
    case HifzGoal.fullQuran:
      upToExclusive = all.length;
      break;
  }
  upToExclusive ??= all.length;

  // Prochains versets non encore mémorisés dans la range.
  final pending = <Verse>[];
  for (var i = from; i < upToExclusive; i++) {
    final v = all[i];
    final status = memo[v.globalIndex];
    if (status != MemorizationStatus.memorized) {
      pending.add(v);
      if (pending.length >= plan.versesPerDay) break;
    }
  }
  return pending;
});

/// Estimation de la date de fin du plan selon la cadence et l'avancement.
final estimatedCompletionProvider = Provider<DateTime?>((ref) {
  final plan = ref.watch(hifzPlanProvider);
  final memo = ref.watch(memorizationProvider);
  final asyncRepo = ref.watch(quranRepositoryProvider);
  final repo = asyncRepo.value;
  if (plan == null || repo == null) return null;

  // Total versets restant à mémoriser dans la range.
  final all = repo.verses;
  final from = all.indexWhere((v) => v.surahNumber == plan.startSurah);
  if (from < 0) return null;

  int upTo;
  switch (plan.goal) {
    case HifzGoal.surah:
      final target = plan.targetSurahOrJuz ?? plan.startSurah;
      final lastIndex = all.lastIndexWhere((v) => v.surahNumber == target);
      upTo = lastIndex >= 0 ? lastIndex + 1 : all.length;
      break;
    case HifzGoal.juz:
      final target = plan.targetSurahOrJuz ?? all[from].juz;
      final lastIndex = all.lastIndexWhere((v) => v.juz == target);
      upTo = lastIndex >= 0 ? lastIndex + 1 : all.length;
      break;
    case HifzGoal.fullQuran:
      upTo = all.length;
      break;
  }

  var remaining = 0;
  for (var i = from; i < upTo; i++) {
    if (memo[all[i].globalIndex] != MemorizationStatus.memorized) {
      remaining++;
    }
  }
  if (remaining == 0) return DateTime.now();
  final days = (remaining / plan.versesPerDay).ceil();
  return DateTime.now().add(Duration(days: days));
});
