// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نوران';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabRead => 'قراءة';

  @override
  String get tabHifz => 'الحفظ';

  @override
  String get tabMurajaa => 'المراجعة';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get greetingMorning => 'السلام عليكم';

  @override
  String get greetingEvening => 'السلام عليكم';

  @override
  String get todayPlan => 'خطة اليوم';

  @override
  String get versesToMemorize => 'آيات للحفظ';

  @override
  String get versesToReview => 'آيات للمراجعة';

  @override
  String currentStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days أيام',
      one: 'يوم واحد',
      zero: 'بدون أيام',
    );
    return '$_temp0 متتالية';
  }

  @override
  String get continueMemorizing => 'متابعة الحفظ';

  @override
  String get startReview => 'بدء المراجعة';

  @override
  String get openMushaf => 'فتح المصحف';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsReciter => 'القارئ الافتراضي';

  @override
  String get settingsTranslation => 'الترجمة الافتراضية';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSepia => 'بني داكن (قراءة)';

  @override
  String get themeSystem => 'النظام';

  @override
  String get emptyStatePlanTitle => 'لا توجد خطة حالية';

  @override
  String get emptyStatePlanDescription =>
      'ابدأ خطة الحفظ المخصصة لك لبدء رحلة حفظ القرآن.';

  @override
  String get emptyStatePlanCta => 'إنشاء خطتي';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get audioSpeed => 'السرعة';

  @override
  String get audioRepeat => 'التكرار';

  @override
  String get audioReciter => 'القارئ';

  @override
  String get audioPlayFromHere => 'ابدأ من هنا';

  @override
  String get audioPlayRange => 'نطاق التشغيل';

  @override
  String get audioOnce => 'مرة واحدة';

  @override
  String audioRepeatN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n مرات',
      one: 'مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reciterSlowBadge => 'بطيء (تعليم)';
}
