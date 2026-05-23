/// 4 sous-modes du Mode Test.
enum HifzTestMode {
  firstWord,
  lastWord,
  nextVerse,
  previousVerse,
}

extension HifzTestModeX on HifzTestMode {
  String get label => switch (this) {
        HifzTestMode.firstWord => 'Premier mot',
        HifzTestMode.lastWord => 'Dernier mot',
        HifzTestMode.nextVerse => 'Verset suivant',
        HifzTestMode.previousVerse => 'Verset précédent',
      };

  String get description => switch (this) {
        HifzTestMode.firstWord => 'Devinez le premier mot manquant de chaque verset',
        HifzTestMode.lastWord => 'Devinez le dernier mot manquant de chaque verset',
        HifzTestMode.nextVerse => 'Trouvez quel verset vient juste après',
        HifzTestMode.previousVerse => 'Trouvez quel verset vient juste avant',
      };
}
