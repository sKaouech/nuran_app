/// Sources de tafsir disponibles dans l'app.
enum TafsirSource {
  muyassarAr('muyassar_ar', 'Al-Muyassar', 'العربية', 'Tafsir simplifié officiel'),
  jalalaynAr('jalalayn_ar', 'Al-Jalalayn', 'العربية', 'Très court, mot-à-mot'),
  maududiEn('maududi_en', 'Maududi', 'English', 'Tafhim al-Quran (anglais)');

  const TafsirSource(this.id, this.title, this.language, this.description);
  final String id;
  final String title;
  final String language;
  final String description;

  String get assetPath => 'assets/data/tafsir_$id.json';
  bool get isArabic => language == 'العربية';
}
