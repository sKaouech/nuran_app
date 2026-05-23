// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nuran';

  @override
  String get tabHome => 'Home';

  @override
  String get tabRead => 'Read';

  @override
  String get tabHifz => 'Hifz';

  @override
  String get tabMurajaa => 'Murajaa';

  @override
  String get tabSettings => 'Settings';

  @override
  String get greetingMorning => 'As-salāmu ʿalaykum';

  @override
  String get greetingEvening => 'As-salāmu ʿalaykum';

  @override
  String get todayPlan => 'Your plan today';

  @override
  String get versesToMemorize => 'Verses to memorize';

  @override
  String get versesToReview => 'Verses to review';

  @override
  String currentStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'No days',
    );
    return '$_temp0 streak';
  }

  @override
  String get continueMemorizing => 'Continue memorizing';

  @override
  String get startReview => 'Start review';

  @override
  String get openMushaf => 'Open mushaf';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsReciter => 'Default reciter';

  @override
  String get settingsTranslation => 'Default translation';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSepia => 'Sepia (reading)';

  @override
  String get themeSystem => 'System';

  @override
  String get emptyStatePlanTitle => 'No active plan';

  @override
  String get emptyStatePlanDescription =>
      'Start your personalized memorization plan to begin your Hifz journey.';

  @override
  String get emptyStatePlanCta => 'Create my plan';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get audioSpeed => 'Speed';

  @override
  String get audioRepeat => 'Repeats';

  @override
  String get audioReciter => 'Reciter';

  @override
  String get audioPlayFromHere => 'Play from here';

  @override
  String get audioPlayRange => 'Play range';

  @override
  String get audioOnce => 'Play once';

  @override
  String audioRepeatN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get reciterSlowBadge => 'Slow (learning)';
}
