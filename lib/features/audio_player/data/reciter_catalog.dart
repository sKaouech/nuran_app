import '../domain/entities/reciter.dart';

/// Catalogue des récitateurs supportés.
/// Sources audio : everyayah.com (libres d'utilisation).
class ReciterCatalog {
  ReciterCatalog._();

  static const List<Reciter> all = [
    // Récitateurs principaux (gratuits)
    Reciter(
      id: 'mishary',
      nameEnglish: 'Mishary Rashid Al-Afasy',
      nameArabic: 'مشاري راشد العفاسي',
      everyayahPath: 'Alafasy_128kbps',
      bitrate: 128,
    ),
    Reciter(
      id: 'sudais',
      nameEnglish: 'Abdul Rahman Al-Sudais',
      nameArabic: 'عبد الرحمن السديس',
      everyayahPath: 'Abdurrahmaan_As-Sudais_192kbps',
      bitrate: 192,
    ),
    Reciter(
      id: 'shuraim',
      nameEnglish: 'Saud Al-Shuraim',
      nameArabic: 'سعود الشريم',
      everyayahPath: 'Saood_ash-Shuraym_64kbps',
      bitrate: 64,
    ),
    Reciter(
      id: 'husary',
      nameEnglish: 'Mahmoud Khalil Al-Husary',
      nameArabic: 'محمود خليل الحصري',
      everyayahPath: 'Husary_128kbps',
      bitrate: 128,
    ),
    Reciter(
      id: 'husary_muallim',
      nameEnglish: 'Al-Husary (Muallim — slow)',
      nameArabic: 'الحصري - المعلم',
      everyayahPath: 'Husary_Muallim_128kbps',
      bitrate: 128,
      isSlow: true,
    ),
    Reciter(
      id: 'minshawi',
      nameEnglish: 'Mohamed Siddiq Al-Minshawi',
      nameArabic: 'محمد صديق المنشاوي',
      everyayahPath: 'Minshawy_Murattal_128kbps',
      bitrate: 128,
    ),
    Reciter(
      id: 'minshawi_muallim',
      nameEnglish: 'Al-Minshawi (Muallim — slow)',
      nameArabic: 'المنشاوي - المعلم',
      everyayahPath: 'Minshawy_Mujawwad_192kbps',
      bitrate: 192,
      isSlow: true,
    ),
    Reciter(
      id: 'maher',
      nameEnglish: 'Maher Al-Mueaqly',
      nameArabic: 'ماهر المعيقلي',
      everyayahPath: 'MaherAlMuaiqly128kbps',
      bitrate: 128,
    ),
    Reciter(
      id: 'ghamdi',
      nameEnglish: 'Saad Al-Ghamdi',
      nameArabic: 'سعد الغامدي',
      everyayahPath: 'Ghamadi_40kbps',
      bitrate: 40,
    ),
    Reciter(
      id: 'abdulbasit',
      nameEnglish: 'Abdul Basit Abdul Samad',
      nameArabic: 'عبد الباسط عبد الصمد',
      everyayahPath: 'Abdul_Basit_Murattal_64kbps',
      bitrate: 64,
    ),
  ];

  static Reciter byId(String id) =>
      all.firstWhere((r) => r.id == id, orElse: () => all.first);

  static const defaultReciterId = 'mishary';
}
