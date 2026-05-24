import 'package:flutter/foundation.dart';

/// État d'un téléchargement d'une sourate complète chez un récitateur.
enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

@immutable
class DownloadTask {
  const DownloadTask({
    required this.reciterId,
    required this.surahNumber,
    required this.totalVerses,
    required this.status,
    required this.completedVerses,
    this.errorMessage,
  });

  /// Identifiant du récitateur (ex: 'husary').
  final String reciterId;

  /// Numéro de sourate (1..114).
  final int surahNumber;

  /// Nombre total de versets de la sourate (utilisé pour le calcul du %).
  final int totalVerses;

  /// Versets téléchargés avec succès dans cette session.
  final int completedVerses;

  final DownloadStatus status;

  final String? errorMessage;

  /// Clé unique pour ce téléchargement (utilisée dans les maps).
  String get key => '$reciterId/$surahNumber';

  /// Pourcentage de progression (0-100).
  double get progressPercent {
    if (totalVerses == 0) return 0;
    return (completedVerses / totalVerses) * 100;
  }

  bool get isComplete =>
      status == DownloadStatus.downloaded || completedVerses >= totalVerses;

  DownloadTask copyWith({
    int? completedVerses,
    DownloadStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadTask(
      reciterId: reciterId,
      surahNumber: surahNumber,
      totalVerses: totalVerses,
      completedVerses: completedVerses ?? this.completedVerses,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() => {
        'r': reciterId,
        's': surahNumber,
        't': totalVerses,
        'c': completedVerses,
        'st': status.name,
        'e': errorMessage,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        reciterId: json['r'] as String,
        surahNumber: json['s'] as int,
        totalVerses: json['t'] as int,
        completedVerses: json['c'] as int,
        status: DownloadStatus.values.firstWhere(
          (s) => s.name == json['st'],
          orElse: () => DownloadStatus.notDownloaded,
        ),
        errorMessage: json['e'] as String?,
      );
}
