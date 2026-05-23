import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Nuran'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// No description provided for @tabRead.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get tabRead;

  /// No description provided for @tabHifz.
  ///
  /// In fr, this message translates to:
  /// **'Hifz'**
  String get tabHifz;

  /// No description provided for @tabMurajaa.
  ///
  /// In fr, this message translates to:
  /// **'Murajaa'**
  String get tabMurajaa;

  /// No description provided for @tabSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get tabSettings;

  /// No description provided for @greetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'As-salāmu ʿalaykum'**
  String get greetingMorning;

  /// No description provided for @greetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'As-salāmu ʿalaykum'**
  String get greetingEvening;

  /// No description provided for @todayPlan.
  ///
  /// In fr, this message translates to:
  /// **'Votre plan du jour'**
  String get todayPlan;

  /// No description provided for @versesToMemorize.
  ///
  /// In fr, this message translates to:
  /// **'Versets à mémoriser'**
  String get versesToMemorize;

  /// No description provided for @versesToReview.
  ///
  /// In fr, this message translates to:
  /// **'Versets à réviser'**
  String get versesToReview;

  /// No description provided for @currentStreak.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Aucun jour} =1{1 jour} other{{days} jours}} de suite'**
  String currentStreak(int days);

  /// No description provided for @continueMemorizing.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la mémorisation'**
  String get continueMemorizing;

  /// No description provided for @startReview.
  ///
  /// In fr, this message translates to:
  /// **'Commencer la révision'**
  String get startReview;

  /// No description provided for @openMushaf.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le mushaf'**
  String get openMushaf;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsReciter.
  ///
  /// In fr, this message translates to:
  /// **'Récitateur par défaut'**
  String get settingsReciter;

  /// No description provided for @settingsTranslation.
  ///
  /// In fr, this message translates to:
  /// **'Traduction par défaut'**
  String get settingsTranslation;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeSepia.
  ///
  /// In fr, this message translates to:
  /// **'Sépia (lecture)'**
  String get themeSepia;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @emptyStatePlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plan en cours'**
  String get emptyStatePlanTitle;

  /// No description provided for @emptyStatePlanDescription.
  ///
  /// In fr, this message translates to:
  /// **'Démarrez votre plan de mémorisation personnalisé pour commencer le voyage du Hifz.'**
  String get emptyStatePlanDescription;

  /// No description provided for @emptyStatePlanCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon plan'**
  String get emptyStatePlanCta;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @audioSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse'**
  String get audioSpeed;

  /// No description provided for @audioRepeat.
  ///
  /// In fr, this message translates to:
  /// **'Répétitions'**
  String get audioRepeat;

  /// No description provided for @audioReciter.
  ///
  /// In fr, this message translates to:
  /// **'Récitateur'**
  String get audioReciter;

  /// No description provided for @audioPlayFromHere.
  ///
  /// In fr, this message translates to:
  /// **'Lire à partir d\'ici'**
  String get audioPlayFromHere;

  /// No description provided for @audioPlayRange.
  ///
  /// In fr, this message translates to:
  /// **'Lire une plage'**
  String get audioPlayRange;

  /// No description provided for @audioOnce.
  ///
  /// In fr, this message translates to:
  /// **'Lecture unique'**
  String get audioOnce;

  /// No description provided for @audioRepeatN.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 fois} other{{n} fois}}'**
  String audioRepeatN(int n);

  /// No description provided for @reciterSlowBadge.
  ///
  /// In fr, this message translates to:
  /// **'Lent (apprentissage)'**
  String get reciterSlowBadge;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
    case 'fr':
      return AppL10nFr();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
