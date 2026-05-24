import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../audio_player/domain/entities/reciter.dart';

/// Service de téléchargement et de gestion des fichiers audio offline.
///
/// Structure de stockage (sous `getApplicationDocumentsDirectory()`) :
/// ```
/// audio/
///   {reciterId}/
///     001/
///       001001.mp3
///       001002.mp3
///       ...
///     002/
///       ...
/// ```
class AudioDownloadService {
  AudioDownloadService._();
  static final instance = AudioDownloadService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));

  Directory? _audioRoot;

  Future<Directory> _root() async {
    if (_audioRoot != null) return _audioRoot!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/audio');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _audioRoot = dir;
    return dir;
  }

  /// Chemin local attendu pour un verset chez un récitateur (peut ne pas exister).
  Future<String> localPathFor({
    required String reciterId,
    required int surah,
    required int ayah,
  }) async {
    final root = await _root();
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '${root.path}/$reciterId/$s/$s$a.mp3';
  }

  /// Renvoie le fichier local s'il existe, sinon null.
  Future<File?> existingLocalFile({
    required String reciterId,
    required int surah,
    required int ayah,
  }) async {
    final path = await localPathFor(
      reciterId: reciterId,
      surah: surah,
      ayah: ayah,
    );
    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 1024) {
      // Sanity check : un MP3 valide fait au moins quelques KB
      return file;
    }
    return null;
  }

  /// True si la sourate entière est téléchargée pour ce récitateur.
  Future<bool> isSurahFullyDownloaded({
    required String reciterId,
    required int surah,
    required int totalVerses,
  }) async {
    for (var ayah = 1; ayah <= totalVerses; ayah++) {
      final file = await existingLocalFile(
        reciterId: reciterId,
        surah: surah,
        ayah: ayah,
      );
      if (file == null) return false;
    }
    return true;
  }

  /// Télécharge la sourate complète chez ce récitateur.
  /// [onProgress] est appelé après chaque verset téléchargé.
  Future<void> downloadSurah({
    required Reciter reciter,
    required int surah,
    required int totalVerses,
    required void Function(int completed) onProgress,
    bool Function()? shouldCancel,
  }) async {
    var done = 0;
    for (var ayah = 1; ayah <= totalVerses; ayah++) {
      if (shouldCancel?.call() == true) return;

      // Skip si déjà téléchargé
      final existing = await existingLocalFile(
        reciterId: reciter.id,
        surah: surah,
        ayah: ayah,
      );
      if (existing != null) {
        done++;
        onProgress(done);
        continue;
      }

      final url = reciter.audioUrlFor(surah: surah, ayah: ayah);
      final destPath = await localPathFor(
        reciterId: reciter.id,
        surah: surah,
        ayah: ayah,
      );

      // Crée le dossier de la sourate si nécessaire
      final destFile = File(destPath);
      if (!destFile.parent.existsSync()) {
        await destFile.parent.create(recursive: true);
      }

      try {
        await _dio.download(
          url,
          destPath,
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );
        done++;
        onProgress(done);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Download] Failed $url : $e');
        }
        // On supprime un fichier partiel
        if (destFile.existsSync()) {
          await destFile.delete();
        }
        rethrow;
      }
    }
  }

  /// Supprime tous les fichiers audio d'une sourate pour un récitateur.
  Future<void> deleteSurah({
    required String reciterId,
    required int surah,
  }) async {
    final root = await _root();
    final s = surah.toString().padLeft(3, '0');
    final dir = Directory('${root.path}/$reciterId/$s');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// Supprime tous les téléchargements d'un récitateur.
  Future<void> deleteReciter(String reciterId) async {
    final root = await _root();
    final dir = Directory('${root.path}/$reciterId');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// Supprime absolument tout.
  Future<void> deleteAll() async {
    final root = await _root();
    if (root.existsSync()) {
      await root.delete(recursive: true);
      _audioRoot = null;
    }
  }

  /// Taille totale en bytes occupée par les téléchargements.
  Future<int> totalSizeBytes() async {
    final root = await _root();
    if (!root.existsSync()) return 0;
    var total = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File) {
        total += entity.lengthSync();
      }
    }
    return total;
  }

  /// Format human-readable de taille (B, KB, MB, GB).
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
