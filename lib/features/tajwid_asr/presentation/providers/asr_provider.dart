import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// État de la session ASR.
@immutable
class AsrState {
  const AsrState({
    this.isListening = false,
    this.isAvailable = false,
    this.recognizedText = '',
    this.errorMessage,
    this.soundLevel = 0,
  });

  final bool isListening;
  final bool isAvailable;
  final String recognizedText;
  final String? errorMessage;
  final double soundLevel;

  AsrState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? recognizedText,
    String? errorMessage,
    double? soundLevel,
    bool clearError = false,
  }) {
    return AsrState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedText: recognizedText ?? this.recognizedText,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

class AsrController extends StateNotifier<AsrState> {
  AsrController() : super(const AsrState());

  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Initialise le moteur ASR + demande les permissions.
  /// Retourne true si l'arabe est disponible.
  Future<bool> initialize() async {
    final available = await _speech.initialize(
      onError: (e) {
        state = state.copyWith(
          errorMessage: e.errorMsg,
          isListening: false,
        );
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          state = state.copyWith(isListening: false);
        }
      },
    );
    state = state.copyWith(isAvailable: available, clearError: true);
    return available;
  }

  /// Démarre l'écoute avec locale arabe.
  Future<void> startListening({
    String localeId = 'ar-SA',
  }) async {
    if (state.isListening) return;
    if (!state.isAvailable) {
      final ok = await initialize();
      if (!ok) return;
    }

    state = state.copyWith(
      isListening: true,
      recognizedText: '',
      clearError: true,
    );

    await _speech.listen(
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
      onResult: (result) {
        state = state.copyWith(recognizedText: result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        state = state.copyWith(soundLevel: level);
      },
    );
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancel() async {
    await _speech.cancel();
    state = const AsrState();
  }

  void reset() {
    state = const AsrState();
  }
}

final asrControllerProvider =
    StateNotifierProvider<AsrController, AsrState>((ref) {
  return AsrController();
});
