// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Nuran';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabRead => 'Lire';

  @override
  String get tabHifz => 'Hifz';

  @override
  String get tabMurajaa => 'Murajaa';

  @override
  String get tabSettings => 'Réglages';

  @override
  String get greetingMorning => 'As-salāmu ʿalaykum';

  @override
  String get greetingEvening => 'As-salāmu ʿalaykum';

  @override
  String get todayPlan => 'Votre plan du jour';

  @override
  String get versesToMemorize => 'Versets à mémoriser';

  @override
  String get versesToReview => 'Versets à réviser';

  @override
  String currentStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
      zero: 'Aucun jour',
    );
    return '$_temp0 de suite';
  }

  @override
  String get continueMemorizing => 'Continuer la mémorisation';

  @override
  String get startReview => 'Commencer la révision';

  @override
  String get openMushaf => 'Ouvrir le mushaf';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsReciter => 'Récitateur par défaut';

  @override
  String get settingsTranslation => 'Traduction par défaut';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSepia => 'Sépia (lecture)';

  @override
  String get themeSystem => 'Système';

  @override
  String get emptyStatePlanTitle => 'Aucun plan en cours';

  @override
  String get emptyStatePlanDescription =>
      'Démarrez votre plan de mémorisation personnalisé pour commencer le voyage du Hifz.';

  @override
  String get emptyStatePlanCta => 'Créer mon plan';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get audioSpeed => 'Vitesse';

  @override
  String get audioRepeat => 'Répétitions';

  @override
  String get audioReciter => 'Récitateur';

  @override
  String get audioPlayFromHere => 'Lire à partir d\'ici';

  @override
  String get audioPlayRange => 'Lire une plage';

  @override
  String get audioOnce => 'Lecture unique';

  @override
  String audioRepeatN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fois',
      one: '1 fois',
    );
    return '$_temp0';
  }

  @override
  String get reciterSlowBadge => 'Lent (apprentissage)';
}
