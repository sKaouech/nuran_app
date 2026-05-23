// Script outil — exécuter avec `dart run tool/compact_quran_data.dart`.
// Transforme les JSON bruts de alquran.cloud en JSON compacts embarqués dans l'app.
import 'dart:convert';
import 'dart:io';

void main() async {
  final assetsDir = Directory('assets/data');

  // 1. Sourates (métadonnées) — extraites du fichier uthmani
  final uthmaniFile = File('${assetsDir.path}/quran_uthmani_raw.json');
  final uthmaniJson = json.decode(await uthmaniFile.readAsString()) as Map<String, dynamic>;
  final surahsRaw = (uthmaniJson['data']['surahs'] as List).cast<Map<String, dynamic>>();

  final surahs = <Map<String, dynamic>>[];
  final versesUthmani = <Map<String, dynamic>>[];

  for (final s in surahsRaw) {
    surahs.add({
      'n': s['number'],
      'name_ar': s['name'],
      'name_en': s['englishName'],
      'name_en_tr': s['englishNameTranslation'],
      'type': s['revelationType'], // Meccan / Medinan
      'count': (s['ayahs'] as List).length,
    });

    for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
      versesUthmani.add({
        's': s['number'],
        'a': a['number'] is int ? a['number'] : a['numberInSurah'],
        'i': a['numberInSurah'],
        't': a['text'],
        'j': a['juz'],
        'h': a['hizbQuarter'],
        'p': a['page'],
      });
    }
  }

  await File('${assetsDir.path}/surahs.json').writeAsString(json.encode(surahs));
  await File('${assetsDir.path}/verses_ar_uthmani.json')
      .writeAsString(json.encode(versesUthmani));
  stdout.writeln('✓ surahs.json: ${surahs.length} sourates');
  stdout.writeln('✓ verses_ar_uthmani.json: ${versesUthmani.length} versets');

  // 2. Traductions (texte uniquement, indexées par numéro global)
  for (final lang in ['fr_hamidullah', 'en_sahih']) {
    final f = File('${assetsDir.path}/quran_${lang}_raw.json');
    final raw = json.decode(await f.readAsString()) as Map<String, dynamic>;
    final sList = (raw['data']['surahs'] as List).cast<Map<String, dynamic>>();
    final out = <String>[];
    for (final s in sList) {
      for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
        out.add(a['text'] as String);
      }
    }
    await File('${assetsDir.path}/translation_$lang.json')
        .writeAsString(json.encode(out));
    stdout.writeln('✓ translation_$lang.json: ${out.length} traductions');
  }
}
