import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../hifz/presentation/pages/listen_repeat_page.dart';
import '../../../quran_reader/domain/entities/verse.dart';
import '../../../tajwid_asr/presentation/pages/recitation_check_page.dart';
import '../providers/audio_player_provider.dart';
import 'reciter_picker.dart';

/// Menu d'options audio pour un verset (long-press → bottom sheet).
Future<void> showVerseAudioMenu(BuildContext context, Verse verse) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _VerseAudioMenu(verse: verse),
  );
}

class _VerseAudioMenu extends ConsumerStatefulWidget {
  const _VerseAudioMenu({required this.verse});

  final Verse verse;

  @override
  ConsumerState<_VerseAudioMenu> createState() => _VerseAudioMenuState();
}

class _VerseAudioMenuState extends ConsumerState<_VerseAudioMenu> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(audioPlayerProvider);
    final controller = ref.read(audioPlayerProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.verse.surahNumber}:${widget.verse.ayahInSurah}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Vitesse
            Text(l10n.audioSpeed, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [0.5, 0.75, 1.0, 1.25, 1.5].map((s) {
                final selected = state.speed == s;
                return ChoiceChip(
                  label: Text('${s}x'),
                  selected: selected,
                  onSelected: (_) => controller.setSpeed(s),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Répétitions
            Text(l10n.audioRepeat, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [1, 3, 5, 10, 20].map((n) {
                final selected = state.repeatCount == n;
                return ChoiceChip(
                  label: Text(l10n.audioRepeatN(n)),
                  selected: selected,
                  onSelected: (_) => controller.setRepeatCount(n),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Actions
            FilledButton.icon(
              onPressed: () {
                controller.playVerse(
                  surah: widget.verse.surahNumber,
                  ayah: widget.verse.ayahInSurah,
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.audioOnce),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListenRepeatPage(verse: widget.verse),
                  ),
                );
              },
              icon: const Icon(Icons.school),
              label: const Text('Mode Hifz (Écoute & Répète)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RecitationCheckPage(verse: widget.verse),
                  ),
                );
              },
              icon: const Icon(Icons.mic),
              label: const Text('Vérifier ma récitation (ASR)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showReciterPicker(context);
              },
              icon: const Icon(Icons.person_outline),
              label: Text('${l10n.audioReciter} — ${state.reciter.nameEnglish}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
