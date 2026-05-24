import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// État "lent" de la session ASR (ne change pas à chaque tick audio).
@immutable
class AsrState {
  const AsrState({
    this.isListening = false,
    this.isAvailable = false,
    this.errorMessage,
    this.activeLocaleId,
    this.availableLocales = const [],
  });

  final bool isListening;
  final bool isAvailable;
  final String? errorMessage;

  /// Locale réellement utilisée (peut différer de celle demandée si fallback).
  final String? activeLocaleId;

  /// Liste des locales détectées sur l'appareil (pour debug).
  final List<String> availableLocales;

  AsrState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? errorMessage,
    String? activeLocaleId,
    List<String>? availableLocales,
    bool clearError = false,
  }) {
    return AsrState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeLocaleId: activeLocaleId ?? this.activeLocaleId,
      availableLocales: availableLocales ?? this.availableLocales,
    );
  }
}

class AsrController extends StateNotifier<AsrState> {
  AsrController() : super(const AsrState());

  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Transcription temps réel exposée via ValueNotifier (haute fréquence).
  final ValueNotifier<String> recognizedText = ValueNotifier('');

  /// Préférences locales recherchées dans l'ordre. Si l'arabe n'est pas
  /// disponible (cas typique du simulateur iOS), on bascule sur français/anglais
  /// pour permettre au moins le test du matching.
  static const _preferredLocales = ['ar-SA', 'ar', 'ar-EG', 'fr-FR', 'en-US'];

  Future<bool> initialize() async {
    try {
      // 1. Demande explicite des permissions (micro + reconnaissance vocale)
      if (await Permission.microphone.request() != PermissionStatus.granted) {
        state = state.copyWith(
          isAvailable: false,
          errorMessage: 'Permission micro refusée',
        );
        return false;
      }
      // Sur iOS, la reconnaissance vocale a aussi sa propre permission
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Permission.speech.request();
      }

      // 2. Init du moteur speech_to_text
      final available = await _speech.initialize(
        onError: (e) {
          if (kDebugMode) {
            debugPrint('[ASR] error: ${e.errorMsg} (permanent=${e.permanent})');
          }
          state = state.copyWith(
            errorMessage: e.errorMsg,
            isListening: false,
          );
        },
        onStatus: (status) {
          if (kDebugMode) {
            debugPrint('[ASR] status: $status');
          }
          if (status == 'done' || status == 'notListening') {
            if (state.isListening) {
              state = state.copyWith(isListening: false);
            }
          }
        },
        debugLogging: kDebugMode,
      );

      if (!available) {
        state = state.copyWith(
          isAvailable: false,
          errorMessage: 'Reconnaissance vocale indisponible sur cet appareil',
        );
        return false;
      }

      // 3. Liste des locales installées sur l'appareil
      final locales = await _speech.locales();
      final localeIds = locales.map((l) => l.localeId).toList();
      if (kDebugMode) {
        debugPrint('[ASR] ${localeIds.length} locales available');
        debugPrint('[ASR] Locales: $localeIds');
      }

      state = state.copyWith(
        isAvailable: true,
        availableLocales: localeIds,
        clearError: true,
      );
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ASR] initialize failed: $e\n$st');
      }
      state = state.copyWith(
        isAvailable: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Cherche la meilleure locale disponible (arabe en priorité, sinon fallback).
  String _pickBestLocale() {
    final available = state.availableLocales;
    if (available.isEmpty) return 'en-US';

    for (final preferred in _preferredLocales) {
      // Match exact
      if (available.contains(preferred)) return preferred;
      // Match par préfixe (ex: "ar" match "ar-SA")
      final matching = available.firstWhere(
        (l) => l.toLowerCase().startsWith(preferred.toLowerCase().split('-')[0]),
        orElse: () => '',
      );
      if (matching.isNotEmpty) return matching;
    }
    return available.first;
  }

  Future<void> startListening() async {
    if (state.isListening) return;
    if (!state.isAvailable) {
      final ok = await initialize();
      if (!ok) return;
    }

    final locale = _pickBestLocale();
    if (kDebugMode) {
      debugPrint('[ASR] startListening with locale: $locale');
    }

    recognizedText.value = '';
    state = state.copyWith(
      isListening: true,
      activeLocaleId: locale,
      clearError: true,
    );

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        localeId: locale,
        onResult: (result) {
          if (kDebugMode && result.finalResult) {
            debugPrint('[ASR] final: ${result.recognizedWords}');
          }
          recognizedText.value = result.recognizedWords;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ASR] listen failed: $e');
      }
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Échec démarrage écoute : $e',
      );
    }
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
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
