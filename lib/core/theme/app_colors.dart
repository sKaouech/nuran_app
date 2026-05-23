import 'package:flutter/material.dart';

/// Palette "Calm Islamic" — sérénité du mushaf, modernité 2026.
/// Pas de couleurs criardes. Beaucoup de blanc/crème. Vert profond + or sobre.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1B5E4F); // Vert verdure médinoise
  static const Color primaryContainer = Color(0xFFA7D7C5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF002019);

  static const Color secondary = Color(0xFFB8860B); // Or sobre
  static const Color secondaryContainer = Color(0xFFF5E6B8);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF8B5A2B); // Brun calligraphie
  static const Color tertiaryContainer = Color(0xFFEED9C4);

  // Surface — Light
  static const Color surfaceLight = Color(0xFFFFFBF5); // Crème mushaf
  static const Color surfaceContainerLight = Color(0xFFF5EFE4);
  static const Color surfaceContainerHighLight = Color(0xFFEDE6D6);
  static const Color onSurfaceLight = Color(0xFF1C1B1A);
  static const Color onSurfaceVariantLight = Color(0xFF5A5A57);

  // Surface — Dark
  static const Color surfaceDark = Color(0xFF1C1B1A);
  static const Color surfaceContainerDark = Color(0xFF2A2826);
  static const Color surfaceContainerHighDark = Color(0xFF3A3735);
  static const Color onSurfaceDark = Color(0xFFEDE6D6);
  static const Color onSurfaceVariantDark = Color(0xFFB8B5B0);

  // Surface — Sepia
  static const Color surfaceSepia = Color(0xFFF4ECD8);
  static const Color onSurfaceSepia = Color(0xFF3E2C1C);

  // États sémantiques
  static const Color success = Color(0xFF2E7D5F);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFB91C1C);
  static const Color info = Color(0xFF1E5C8A);

  // FSRS Heatmap (force de mémorisation)
  static const Color srs0 = Color(0xFFE5E7EB); // Non commencé
  static const Color srs1 = Color(0xFFFCA5A5); // Rouge — oublié
  static const Color srs2 = Color(0xFFFCD34D); // Jaune — fragile
  static const Color srs3 = Color(0xFF86EFAC); // Vert clair — stable
  static const Color srs4 = Color(0xFF22C55E); // Vert — mémorisé
  static const Color srs5 = Color(0xFF15803D); // Vert profond — maîtrisé
}
