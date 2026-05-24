import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// État "lent" de la session ASR (ne change pas à chaque tick audio).
///
/// On garde **uniquement** les changements à basse fréquence dans le state
/// Riverpod (isListening, isAvailable, error). La transcription temps réel
/// passe par un `ValueNotifier` séparé pour éviter les notifications massives
/// qui causent des `markNeedsBuild on defunct element` quand le widget se
/// redessine pendant qu'un autre est en train d'être disposé.
@immutable
class AsrState {
  const AsrState({
    this.isListening = false,
    this.isAvailable = false,
    this.errorMessage,
  });

  final bool isListening;
  final bool isAvailable;
  final String? errorMessage;

  AsrState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AsrState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AsrController extends StateNotifier<AsrState> {
  AsrController() : super(const AsrState());

  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Transcription temps réel — exposée via ValueNotifier pour permettre aux
  /// widgets de s'y abonner sans passer par Riverpod (= sans risquer de
  /// déclencher markNeedsBuild sur des éléments defunct).
  final ValueNotifier<String> recognizedText = ValueNotifier('');

  /// Initialise le moteur ASR + demande les permissions.
  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onError: (e) {
          state = state.copyWith(
            errorMessage: e.errorMsg,
            isListening: false,
          );
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (state.isListening) {
              state = state.copyWith(isListening: false);
            }
          }
        },
      );
      state = state.copyWith(isAvailable: available, clearError: true);
      return available;
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Démarre l'écoute avec locale arabe.
  Future<void> startListening({String localeId = 'ar-SA'}) async {
    if (state.isListening) return;
    if (!state.isAvailable) {
      final ok = await initialize();
      if (!ok) return;
    }

    recognizedText.value = '';
    state = state.copyWith(
      isListening: true,
      clearError: true,
    );

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
      localeId: localeId,
      onResult: (result) {
        // ValueNotifier → mise à jour locale uniquement, pas de propagation
        // Riverpod sur du high-frequency.
        recognizedText.value = result.recognizedWords;
      },
      // soundLevel intentionnellement non-câblé : ce flux est trop rapide
      // et causait des markNeedsBuild on defunct dans Riverpod.
    );
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // L'utilisateur a quitté la page, on ignore les erreurs résiduelles.
    }
    recognizedText.value = '';
    if (mounted) {
      state = const AsrState();
    }
  }

  @override
  void dispose() {
    recognizedText.dispose();
    super.dispose();
  }
}

final asrControllerProvider =
    StateNotifierProvider<AsrController, AsrState>((ref) {
  return AsrController();
});
