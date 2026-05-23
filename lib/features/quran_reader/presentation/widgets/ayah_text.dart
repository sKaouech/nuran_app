import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/tajwid_rules.dart';

/// Widget réutilisable pour afficher un texte arabe coranique avec :
/// - direction RTL automatique
/// - colorisation optionnelle des règles tajwid (madd, ghunnah, qalqalah)
class AyahText extends StatelessWidget {
  const AyahText({
    super.key,
    required this.text,
    required this.tajwidColorsEnabled,
    this.fontSize = 24,
    this.textAlign = TextAlign.right,
  });

  final String text;
  final bool tajwidColorsEnabled;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface;

    if (!tajwidColorsEnabled) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          text,
          style: AppTypography.ayahMedium(baseColor)
              .copyWith(fontSize: fontSize),
          textAlign: textAlign,
        ),
      );
    }

    final segments = TajwidAnalyzer.analyze(text);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: [
            for (final seg in segments)
              TextSpan(
                text: seg.text,
                style: AppTypography.ayahMedium(
                  seg.rule?.color ?? baseColor,
                ).copyWith(fontSize: fontSize),
              ),
          ],
        ),
        textAlign: textAlign,
      ),
    );
  }
}
