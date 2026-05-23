import 'package:flutter_test/flutter_test.dart';
import 'package:nuran/features/quran_reader/data/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranRepository', () {
    late QuranRepository repo;

    setUpAll(() async {
      repo = await QuranRepository.load();
    });

    test('loads 114 surahs', () {
      expect(repo.surahs.length, 114);
    });

    test('loads 6236 verses', () {
      expect(repo.verses.length, 6236);
    });

    test('Al-Fatiha has 7 verses', () {
      final fatiha = repo.versesOfSurah(1);
      expect(fatiha.length, 7);
    });

    test('Al-Baqarah has 286 verses', () {
      final baqarah = repo.versesOfSurah(2);
      expect(baqarah.length, 286);
    });

    test('first verse is Bismillah of Al-Fatiha', () {
      final v = repo.verses.first;
      expect(v.surahNumber, 1);
      expect(v.ayahInSurah, 1);
      expect(v.arabicText, contains('بِسْمِ'));
    });

    test('FR translation of first verse exists', () {
      final tr = repo.translationOf(repo.verses.first, 'fr');
      expect(tr, isNotNull);
      expect(tr!.toLowerCase(), contains('miséricordieux'));
    });

    test('EN translation of first verse exists', () {
      final tr = repo.translationOf(repo.verses.first, 'en');
      expect(tr, isNotNull);
      expect(tr!.toLowerCase(), contains('merciful'));
    });
  });
}
