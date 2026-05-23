import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuran/core/localization/l10n/app_localizations.dart';

import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../audio_player/presentation/widgets/reciter_picker.dart';
import '../../../notifications/notifications_service.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../../shared/providers/reading_preferences_provider.dart';
import '../../../../shared/providers/theme_mode_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final audioState = ref.watch(audioPlayerProvider);
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_localeLabel(locale)),
            onTap: () => _showLanguagePicker(context, ref, locale),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsTheme),
            subtitle: Text(_themeLabel(l10n, themeMode)),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsReciter),
            subtitle: Text(
              isArabic
                  ? audioState.reciter.nameArabic
                  : audioState.reciter.nameEnglish,
            ),
            onTap: () => showReciterPicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.settingsTranslation),
            subtitle: Text(_translationLabel(
              ref.watch(readingPreferencesProvider).translationLang,
            )),
            onTap: () => _showTranslationPicker(context, ref),
          ),
          const Divider(),
          _FontScaleTile(),
          const Divider(),
          _NotificationsTile(),
        ],
      ),
    );
  }

  void _showTranslationPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(readingPreferencesProvider).translationLang;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lang in const ['fr', 'en'])
              ListTile(
                leading: Icon(
                  lang == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: lang == current
                      ? Theme.of(ctx).colorScheme.primary
                      : null,
                ),
                title: Text(_translationLabel(lang)),
                onTap: () {
                  ref
                      .read(readingPreferencesProvider.notifier)
                      .setTranslation(lang);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _translationLabel(String lang) => switch (lang) {
        'fr' => 'Français — Hamidullah',
        'en' => 'English — Sahih International',
        _ => lang,
      };

  String _localeLabel(Locale locale) => switch (locale.languageCode) {
        'fr' => 'Français',
        'ar' => 'العربية',
        'en' => 'English',
        _ => locale.languageCode,
      };

  String _themeLabel(AppL10n l10n, AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => l10n.themeSystem,
        AppThemeMode.light => l10n.themeLight,
        AppThemeMode.dark => l10n.themeDark,
        AppThemeMode.sepia => l10n.themeSepia,
      };

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    Locale current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: supportedLocales.map((locale) {
            final selected = locale.languageCode == current.languageCode;
            return ListTile(
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected
                    ? Theme.of(ctx).colorScheme.primary
                    : null,
              ),
              title: Text(_localeLabel(locale)),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(locale);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = AppL10n.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((mode) {
              final selected = mode == current;
              return ListTile(
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? Theme.of(ctx).colorScheme.primary
                      : null,
                ),
                title: Text(_themeLabel(l10n, mode)),
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _NotificationsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Rappel quotidien'),
          subtitle: Text(
            prefs.enabled
                ? 'Activé à ${prefs.timeLabel}'
                : 'Désactivé',
          ),
          value: prefs.enabled,
          onChanged: (v) async {
            final ok = await ref
                .read(notificationPrefsProvider.notifier)
                .setEnabled(v);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Permissions notifications refusées. Activez-les depuis les réglages système.',
                  ),
                ),
              );
            }
          },
        ),
        if (prefs.enabled)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Heure du rappel'),
            subtitle: Text(prefs.timeLabel),
            onTap: () async {
              final result = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
              );
              if (result != null) {
                await ref.read(notificationPrefsProvider.notifier).setTime(
                      result.hour,
                      result.minute,
                    );
              }
            },
          ),
      ],
    );
  }
}

class _FontScaleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readingPreferencesProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Taille du texte arabe',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text('${(prefs.fontScale * 100).toInt()}%'),
            ],
          ),
          Slider(
            value: prefs.fontScale,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: '${(prefs.fontScale * 100).toInt()}%',
            onChanged: (v) =>
                ref.read(readingPreferencesProvider.notifier).setFontScale(v),
          ),
        ],
      ),
    );
  }
}
