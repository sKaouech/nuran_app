import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../quran_reader/data/quran_repository.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../domain/memorization_status.dart';
import 'memorization_provider.dart';

/// File de versets à réviser : tous ceux avec statut `needsReview`,
/// triés par sourate puis ayah.
final reviewQueueProvider = Provider<List<Verse>>((ref) {
  final memo = ref.watch(memorizationProvider);
  final asyncRepo = ref.watch(quranRepositoryProvider);
  final repo = asyncRepo.value;
  if (repo == null) return const [];

  final indices = memo.entries
      .where((e) => e.value == MemorizationStatus.needsReview)
      .map((e) => e.key)
      .toList()
    ..sort();

  return [for (final i in indices) repo.verses[i - 1]];
});
