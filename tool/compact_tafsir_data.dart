// Script outil : transforme les tafsirs bruts (alquran.cloud) en JSON compacts
// arrays de strings indexées par globalIndex (1..6236).
// Exécution : `dart run tool/compact_tafsir_data.dart`

import 'dart:convert';
import 'dart:io';

void main() async {
  const sources = {
    'muyassar_ar': 'tafsir_muyassar_ar',
    'jalalayn_ar': 'tafsir_jalalayn_ar',
    'maududi_en': 'tafsir_maududi_en',
  };

  for (final entry in sources.entries) {
    final inPath = 'assets/data/raw_tafsir/${entry.key}.json';
    final outPath = 'assets/data/${entry.value}.json';

    final raw = await File(inPath).readAsString();
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final surahs = (decoded['data']['surahs'] as List).cast<Map<String, dynamic>>();

    final out = <String>[];
    for (final s in surahs) {
      for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
        out.add(a['text'] as String);
      }
    }

    await File(outPath).writeAsString(json.encode(out));
    final size = await File(outPath).length();
    stdout.writeln('✓ ${entry.value}.json — ${out.length} versets — ${(size / 1024).toStringAsFixed(0)} KB');
  }
}
