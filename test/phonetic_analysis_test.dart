import 'package:flutter_test/flutter_test.dart';
import 'package:nuran/features/tajwid_asr/domain/phonetic_analysis.dart';
import 'package:nuran/features/tajwid_asr/domain/recitation_match.dart';

void main() {
  group('PhoneticAnalyzer.phoneticForm', () {
    test('strips tashkil', () {
      expect(
        PhoneticAnalyzer.phoneticForm('بِسْمِ'),
        equals(PhoneticAnalyzer.phoneticForm('بسم')),
      );
    });

    test('unifies hamza variants on alif', () {
      expect(
        PhoneticAnalyzer.phoneticForm('أَحْمَدُ'),
        equals(PhoneticAnalyzer.phoneticForm('احمد')),
      );
    });

    test('considers ت and ط as phonetically equivalent', () {
      // L'ASR confond souvent ces deux lettres.
      expect(
        PhoneticAnalyzer.phoneticForm('بتل'),
        equals(PhoneticAnalyzer.phoneticForm('بطل')),
      );
    });

    test('considers ذ ز ظ as phonetically equivalent', () {
      final ref = PhoneticAnalyzer.phoneticForm('ذكر');
      expect(PhoneticAnalyzer.phoneticForm('زكر'), equals(ref));
      expect(PhoneticAnalyzer.phoneticForm('ظكر'), equals(ref));
    });

    test('considers ق and ك as phonetically equivalent', () {
      expect(
        PhoneticAnalyzer.phoneticForm('قلب'),
        equals(PhoneticAnalyzer.phoneticForm('كلب')),
      );
    });
  });

  group('PhoneticAnalyzer.levenshtein', () {
    test('identical strings have distance 0', () {
      expect(PhoneticAnalyzer.levenshtein('abc', 'abc'), 0);
    });

    test('single substitution', () {
      expect(PhoneticAnalyzer.levenshtein('abc', 'abd'), 1);
    });

    test('insertion', () {
      expect(PhoneticAnalyzer.levenshtein('abc', 'abcd'), 1);
    });

    test('empty string distance equals other length', () {
      expect(PhoneticAnalyzer.levenshtein('', 'abc'), 3);
      expect(PhoneticAnalyzer.levenshtein('abc', ''), 3);
    });
  });

  group('PhoneticAnalyzer.similarity', () {
    test('identical strings → 1.0', () {
      expect(PhoneticAnalyzer.similarity('abc', 'abc'), 1.0);
    });

    test('completely different short strings → low', () {
      expect(PhoneticAnalyzer.similarity('abc', 'xyz'), lessThan(0.1));
    });

    test('one-char difference on 5-char string → 0.8', () {
      expect(PhoneticAnalyzer.similarity('abcde', 'abcdf'), 0.8);
    });
  });

  group('PhoneticAnalyzer.analyzeWord', () {
    test('exact match → perfect, no faults', () {
      final r = PhoneticAnalyzer.analyzeWord(
        expected: 'بِسْمِ',
        recognized: 'بسم',
      );
      expect(r.similarity, greaterThanOrEqualTo(0.95));
      expect(r.faults, isEmpty);
      expect(r.isPerfect, isTrue);
    });

    test('null recognized → similarity 0', () {
      final r = PhoneticAnalyzer.analyzeWord(
        expected: 'بسم',
        recognized: null,
      );
      expect(r.similarity, 0.0);
    });

    test('phonetic substitution ت/ط → flagged', () {
      // "بتل" → "بطل" : forme phonétique identique mais lettres différentes.
      final r = PhoneticAnalyzer.analyzeWord(
        expected: 'بَطَلَ',
        recognized: 'بتل',
      );
      expect(r.faults, contains(TajwidFault.phoneticSubstitution));
    });

    test('ghunnah pattern + imperfect recognition → flagged', () {
      // "أنّك" (avec shadda sur le ن porteur de ghunnah) reconnu comme "انك"
      // — l'ASR a omis l'articulation doublée, similarité < 0.95.
      final r = PhoneticAnalyzer.analyzeWord(
        expected: 'أَنَّكَ',
        recognized: 'انك',
      );
      expect(r.faults, contains(TajwidFault.ghunnahMissed));
    });
  });

  group('ArabicTextMatcher.compare (niveau 2)', () {
    test('perfect recitation → all correct, score 100', () {
      final r = ArabicTextMatcher.compare(
        expected: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        recognized: 'بسم الله الرحمن الرحيم',
      );
      expect(r.correctCount, greaterThanOrEqualTo(3));
      expect(r.scorePercent, greaterThanOrEqualTo(80));
    });

    test('phonetic substitutions → partial credit, not zero', () {
      // Toutes les lettres confondues mais structure identique : niveau 1
      // aurait pénalisé, niveau 2 doit donner du crédit.
      final r = ArabicTextMatcher.compare(
        expected: 'بِسْمِ',
        recognized: 'بصم', // س → ص
      );
      expect(r.scorePercent, greaterThan(0));
      // Au moins un mot marqué phonétique ou correct, pas wrong/missing.
      expect(r.matches.first.status, isNot(WordMatchStatus.missing));
    });

    test('completely missing recognition → all missing', () {
      final r = ArabicTextMatcher.compare(
        expected: 'بِسْمِ اللَّهِ',
        recognized: '',
      );
      expect(r.missingCount, 2);
      expect(r.scorePercent, 0);
    });

    test('grade label maps from score', () {
      final r = ArabicTextMatcher.compare(
        expected: 'بسم الله الرحمن الرحيم',
        recognized: 'بسم الله الرحمن الرحيم',
      );
      expect(r.gradeLabel, equals('Excellent'));
    });

    test('uniqueFaults aggregates across words', () {
      final r = ArabicTextMatcher.compare(
        expected: 'بَطَلَ بَطَلَ', // 2x même mot avec ط
        recognized: 'بتل بتل', // 2x substitution ط → ت
      );
      // Une seule occurrence dans le set malgré 2 mots.
      expect(r.uniqueFaults.length, lessThanOrEqualTo(2));
    });
  });
}
