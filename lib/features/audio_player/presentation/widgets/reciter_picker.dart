import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/reciter_catalog.dart';
import '../providers/audio_player_provider.dart';

/// Affiche un sélecteur de récitateur dans une modal bottom sheet.
Future<void> showReciterPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ReciterPickerSheet(),
  );
}

class _ReciterPickerSheet extends ConsumerWidget {
  const _ReciterPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final currentId = ref.watch(audioPlayerProvider).reciterId;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.audioReciter,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: ReciterCatalog.all.length,
                itemBuilder: (context, index) {
                  final reciter = ReciterCatalog.all[index];
                  final isSelected = reciter.id == currentId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      child: Icon(
                        isSelected ? Icons.check : Icons.person_outline,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      isArabic ? reciter.nameArabic : reciter.nameEnglish,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: reciter.isSlow
                        ? Text(
                            l10n.reciterSlowBadge,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                            ),
                          )
                        : null,
                    trailing: Text(
                      '${reciter.bitrate} kbps',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .setReciter(reciter.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
