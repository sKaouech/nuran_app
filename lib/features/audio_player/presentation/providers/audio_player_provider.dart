import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/providers/locale_provider.dart';
import '../../../downloads/data/audio_download_service.dart';
import '../../data/reciter_catalog.dart';
import '../../domain/entities/reciter.dart';

/// État global de l'écoute audio.
@immutable
class AudioPlayerState {
  const AudioPlayerState({
    this.currentSurah,
    this.currentAyah,
    this.isPlaying = false,
    this.isLoading = false,
    this.speed = 1.0,
    this.repeatCount = 1,
    this.currentRepeat = 0,
    this.rangeStart,
    this.rangeEnd,
    this.reciterId = ReciterCatalog.defaultReciterId,
  });

  final int? currentSurah;
  final int? currentAyah;
  final bool isPlaying;
  final bool isLoading;
  final double speed;

  /// Nombre de répétitions du verset courant (1 = lecture simple).
  final int repeatCount;
  final int currentRepeat;

  /// Plage [rangeStart..rangeEnd] dans la sourate courante (inclusif).
  /// null = pas de plage active, on lit juste le verset courant.
  final int? rangeStart;
  final int? rangeEnd;

  final String reciterId;

  Reciter get reciter => ReciterCatalog.byId(reciterId);

  bool get hasActiveVerse => currentSurah != null && currentAyah != null;

  AudioPlayerState copyWith({
    int? currentSurah,
    int? currentAyah,
    bool? isPlaying,
    bool? isLoading,
    double? speed,
    int? repeatCount,
    int? currentRepeat,
    int? rangeStart,
    int? rangeEnd,
    String? reciterId,
    bool clearRange = false,
  }) {
    return AudioPlayerState(
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyah: currentAyah ?? this.currentAyah,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
      repeatCount: repeatCount ?? this.repeatCount,
      currentRepeat: currentRepeat ?? this.currentRepeat,
      rangeStart: clearRange ? null : (rangeStart ?? this.rangeStart),
      rangeEnd: clearRange ? null : (rangeEnd ?? this.rangeEnd),
      reciterId: reciterId ?? this.reciterId,
    );
  }
}

class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  AudioPlayerController(this._prefs) : super(const AudioPlayerState()) {
    _init();
  }

  final SharedPreferences _prefs;
  late final AudioPlayer _player;
  StreamSubscription<ProcessingState>? _stateSub;

  static const _kReciterKey = 'audio_default_reciter';
  static const _kSpeedKey = 'audio_default_speed';

  Future<void> _init() async {
    _player = AudioPlayer();

    // Configure la session audio (background, mute switch, etc.).
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // Restaure préférences.
    final savedReciter = _prefs.getString(_kReciterKey);
    final savedSpeed = _prefs.getDouble(_kSpeedKey);
    if (savedReciter != null || savedSpeed != null) {
      state = state.copyWith(
        reciterId: savedReciter,
        speed: savedSpeed,
      );
    }

    _stateSub = _player.processingStateStream.listen(_onProcessingState);
  }

  void _onProcessingState(ProcessingState ps) async {
    if (ps == ProcessingState.completed) {
      await _handleVerseEnd();
    }
  }

  Future<void> _handleVerseEnd() async {
    // 1. Répéter le verset courant si on n'a pas atteint repeatCount.
    if (state.currentRepeat + 1 < state.repeatCount) {
      state = state.copyWith(currentRepeat: state.currentRepeat + 1);
      await _playCurrent();
      return;
    }

    // 2. Si on a une plage active, passer au verset suivant.
    if (state.rangeStart != null && state.rangeEnd != null) {
      final next = (state.currentAyah ?? 0) + 1;
      if (next <= state.rangeEnd!) {
        state = state.copyWith(
          currentAyah: next,
          currentRepeat: 0,
        );
        await _playCurrent();
        return;
      }
    }

    // 3. Sinon on s'arrête.
    state = state.copyWith(
      isPlaying: false,
      currentRepeat: 0,
    );
  }

  Future<void> _playCurrent() async {
    if (!state.hasActiveVerse) return;
    state = state.copyWith(isLoading: true);
    try {
      // Local-first : si le fichier est téléchargé on l'utilise, sinon URL.
      final localFile = await AudioDownloadService.instance.existingLocalFile(
        reciterId: state.reciter.id,
        surah: state.currentSurah!,
        ayah: state.currentAyah!,
      );
      if (localFile != null) {
        await _player.setFilePath(localFile.path);
      } else {
        final url = state.reciter.audioUrlFor(
          surah: state.currentSurah!,
          ayah: state.currentAyah!,
        );
        await _player.setUrl(url);
      }
      await _player.setSpeed(state.speed);
      await _player.play();
      state = state.copyWith(isPlaying: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isPlaying: false, isLoading: false);
    }
  }

  /// Lance la lecture d'un verset unique.
  Future<void> playVerse({required int surah, required int ayah}) async {
    state = state.copyWith(
      currentSurah: surah,
      currentAyah: ayah,
      currentRepeat: 0,
      clearRange: true,
    );
    await _playCurrent();
  }

  /// Lance la lecture d'une plage de versets dans une sourate.
  Future<void> playRange({
    required int surah,
    required int fromAyah,
    required int toAyah,
  }) async {
    state = state.copyWith(
      currentSurah: surah,
      currentAyah: fromAyah,
      rangeStart: fromAyah,
      rangeEnd: toAyah,
      currentRepeat: 0,
    );
    await _playCurrent();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _player.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _player.play();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = const AudioPlayerState();
  }

  static const List<double> speedSteps = [0.5, 0.75, 1.0, 1.25, 1.5];
  static const List<int> repeatSteps = [1, 3, 5, 10, 20];

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _player.setSpeed(speed);
    await _prefs.setDouble(_kSpeedKey, speed);
  }

  /// Bascule sur la vitesse suivante dans le cycle [speedSteps].
  Future<void> cycleSpeed() async {
    final idx = speedSteps.indexOf(state.speed);
    final next = speedSteps[(idx + 1) % speedSteps.length];
    await setSpeed(next);
  }

  Future<void> setRepeatCount(int count) async {
    state = state.copyWith(
      repeatCount: count.clamp(1, 99),
      currentRepeat: 0,
    );
  }

  /// Bascule sur le nombre de répétitions suivant dans le cycle [repeatSteps].
  Future<void> cycleRepeatCount() async {
    final idx = repeatSteps.indexOf(state.repeatCount);
    final next = repeatSteps[(idx + 1) % repeatSteps.length];
    await setRepeatCount(next);
  }

  Future<void> setReciter(String id) async {
    state = state.copyWith(reciterId: id, currentRepeat: 0);
    await _prefs.setString(_kReciterKey, id);
    if (state.hasActiveVerse && state.isPlaying) {
      await _playCurrent();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>((ref) {
  return AudioPlayerController(ref.watch(sharedPreferencesProvider));
});
