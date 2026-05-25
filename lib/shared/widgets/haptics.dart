import 'package:flutter/services.dart';

/// Helpers haptic feedback centralisés pour avoir une UX cohérente sur les
/// actions clés. iOS et Android ont des comportements différents : on utilise
/// les conventions Material/iOS standards.
class Haptics {
  Haptics._();

  /// Sélection : un léger tap pour signaler un choix UI (chip, toggle).
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Action légère : confirmation simple (play, navigation).
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Action moyenne : action importante mais sans gravité (rating FSRS Good).
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Succès : objectif atteint (mémorisé, quiz réussi, complétion).
  static void success() {
    HapticFeedback.heavyImpact();
  }

  /// Erreur : action invalide / mauvaise réponse.
  static void error() {
    HapticFeedback.vibrate();
  }
}
