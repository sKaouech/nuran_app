import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio_player/data/reciter_catalog.dart';
import '../../data/audio_download_service.dart';
import '../../domain/download_task.dart';

/// Notifier qui maintient l'état des téléchargements en cours et terminés.
/// Map clé = "$reciterId/$surahNumber".
class DownloadsNotifier extends StateNotifier<Map<String, DownloadTask>> {
  DownloadsNotifier() : super(const {});

  final AudioDownloadService _service = AudioDownloadService.instance;
  final Set<String> _cancelled = {};

  /// Vérifie au démarrage quelles sourates sont déjà entièrement téléchargées
  /// sur disque pour les hydrater dans le state.
  ///
  /// On ne checke que les sourates courtes par défaut (Juz 'Amma) pour ne pas
  /// scan tout le disque au boot. L'utilisateur déclenchera le scan complet
  /// depuis la page Téléchargements si besoin.
  Future<void> hydrate(
    List<(String reciterId, int surah, int totalVerses)> candidates,
  ) async {
    final updates = <String, DownloadTask>{};
    for (final c in candidates) {
      final downloaded = await _service.isSurahFullyDownloaded(
        reciterId: c.$1,
        surah: c.$2,
        totalVerses: c.$3,
      );
      if (downloaded) {
        final task = DownloadTask(
          reciterId: c.$1,
          surahNumber: c.$2,
          totalVerses: c.$3,
          completedVerses: c.$3,
          status: DownloadStatus.downloaded,
        );
        updates[task.key] = task;
      }
    }
    if (updates.isNotEmpty) {
      state = {...state, ...updates};
    }
  }

  DownloadTask? taskFor({required String reciterId, required int surah}) {
    return state['$reciterId/$surah'];
  }

  bool isDownloaded({required String reciterId, required int surah}) {
    final t = state['$reciterId/$surah'];
    return t?.status == DownloadStatus.downloaded;
  }

  /// Lance le téléchargement complet d'une sourate pour un récitateur donné.
  Future<void> downloadSurah({
    required String reciterId,
    required int surah,
    required int totalVerses,
  }) async {
    final key = '$reciterId/$surah';
    if (state[key]?.status == DownloadStatus.downloading) return;

    _cancelled.remove(key);

    final initial = DownloadTask(
      reciterId: reciterId,
      surahNumber: surah,
      totalVerses: totalVerses,
      completedVerses: 0,
      status: DownloadStatus.downloading,
    );
    state = {...state, key: initial};

    final reciter = ReciterCatalog.byId(reciterId);

    try {
      await _service.downloadSurah(
        reciter: reciter,
        surah: surah,
        totalVerses: totalVerses,
        shouldCancel: () => _cancelled.contains(key),
        onProgress: (completed) {
          state = {
            ...state,
            key: (state[key] ?? initial).copyWith(
              completedVerses: completed,
            ),
          };
        },
      );

      if (_cancelled.contains(key)) {
        // Téléchargement annulé : on retire du state
        final next = Map<String, DownloadTask>.from(state)..remove(key);
        state = next;
        _cancelled.remove(key);
        return;
      }

      state = {
        ...state,
        key: state[key]!.copyWith(status: DownloadStatus.downloaded),
      };
    } catch (e) {
      state = {
        ...state,
        key: (state[key] ?? initial).copyWith(
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        ),
      };
    }
  }

  void cancel({required String reciterId, required int surah}) {
    final key = '$reciterId/$surah';
    _cancelled.add(key);
  }

  Future<void> deleteSurah({
    required String reciterId,
    required int surah,
  }) async {
    await _service.deleteSurah(reciterId: reciterId, surah: surah);
    final key = '$reciterId/$surah';
    final next = Map<String, DownloadTask>.from(state)..remove(key);
    state = next;
  }

  Future<void> deleteReciter(String reciterId) async {
    await _service.deleteReciter(reciterId);
    final next = Map<String, DownloadTask>.from(state)
      ..removeWhere((k, _) => k.startsWith('$reciterId/'));
    state = next;
  }

  Future<void> deleteAll() async {
    await _service.deleteAll();
    state = const {};
  }

  Future<int> totalSizeBytes() => _service.totalSizeBytes();
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, Map<String, DownloadTask>>((ref) {
  return DownloadsNotifier();
});
