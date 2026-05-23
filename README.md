# 📖 Nuran — Mémorisez le Coran, jour après jour

> *« L'application qui transforme la mémorisation du Coran d'un effort solitaire et frustrant en un parcours mesuré, accompagné et durable — du premier verset jusqu'à l'ijazah, et pour toute une vie de Murajaa. »*

**Nuran** (نوران, "double lumière") est une application mobile dédiée à la **mémorisation (Hifz)** et la **révision (Murajaa)** du Saint Coran, avec une expérience moderne et un algorithme scientifique de répétition espacée.

---

## ✨ Différenciateurs

- 🧠 **Première app Coran avec FSRS v4** — algorithme scientifique de répétition espacée adapté aux versets
- 🔊 **10 récitateurs gratuits** avec contrôles avancés (vitesse, répétition, plage)
- 📖 **Mushaf Madinah complet** (604 pages, swipe RTL authentique)
- 🎯 **Modes Hifz multiples** : Écoute & Répète, Masquage progressif, Mode Test QCM
- 📊 **Heatmap "Force du souvenir"** basée sur la stability FSRS par juz
- 🌍 **Multi-langues** FR / AR / EN avec RTL automatique
- 🌙 **3 thèmes** : Clair / Sombre / Sépia
- ⏰ **Rappel quotidien** à heure paramétrable
- 📈 **Statistiques** : streaks, courbe d'apprentissage, KPIs

---

## 🏗️ Stack technique

| Couche | Choix |
|---|---|
| **Mobile** | Flutter 3.44 + Dart 3.12 |
| **State management** | Riverpod 2.5 |
| **Routing** | go_router 14 |
| **Persistance** | SharedPreferences (V1) |
| **Audio** | just_audio + audio_session |
| **I18n** | intl + ARB |
| **Notifications** | flutter_local_notifications |
| **Architecture** | Clean Architecture / Feature-first |

---

## 📂 Structure

```
lib/features/
├── home/              # Dashboard accueil dynamique
├── quran_reader/      # Mushaf, lecture, recherche
├── audio_player/      # Player, récitateurs, mini-player
├── hifz/              # Plans, mode Écoute, Masquage, Test, heatmap FSRS
├── murajaa/           # FSRS v4 (algorithme + UI carrousel)
├── bookmarks/         # Signets + notes libres
├── stats/             # Streaks, KPIs, chart 30 jours
├── notifications/     # Rappel quotidien
└── settings/          # Préférences utilisateur
```

---

## 🚀 Démarrage

### Prérequis
- Flutter 3.x (`brew install --cask flutter`)
- Xcode 16+ pour iOS
- Android Studio + SDK pour Android

### Installation

```bash
git clone https://github.com/sKaouech/nuran_app.git
cd nuran_app
flutter pub get
flutter gen-l10n
```

### Lancer l'app

```bash
# Sur simulateur iOS
open -a Simulator
flutter run

# Sur Chrome (rapide pour itérer sur l'UI)
flutter run -d chrome
```

### Tests

```bash
flutter test
```

---

## 🧠 FSRS v4 — Le différenciateur produit

L'algorithme FSRS (Free Spaced Repetition Scheduler) est le standard scientifique de la répétition espacée, plus efficace que SM-2 (Anki classique). Nuran l'applique au Coran :

- Chaque verset a une **stability** (S) — durée pendant laquelle on prédit que le souvenir reste accessible
- Une **difficulty** (D) — difficulté personnelle de mémorisation
- Une **retrievability** (R) — probabilité actuelle de se souvenir : `R(t,S) = (1 + t/(9·S))⁻¹`
- Une **due_date** calculée pour atteindre 90% de rétention

L'utilisateur note avec 4 grades : Again / Hard / Good / Easy → l'algorithme reprogramme la prochaine review.

Voir `lib/features/murajaa/domain/fsrs_algorithm.dart` pour l'implémentation complète (port de [open-spaced-repetition/fsrs4anki](https://github.com/open-spaced-repetition/fsrs4anki)).

---

## 📚 Sources de données

- **Texte Coran** : Hafs Uthmani via [alquran.cloud](https://alquran.cloud)
- **Traductions** : Hamidullah (FR), Sahih International (EN)
- **Récitations audio** : [everyayah.com](https://everyayah.com) (10 récitateurs libres)
- **Police arabe** : Amiri (libre) — KFGQPC Uthman Taha prévu en V1.1

---

## 🗺️ Roadmap

### V1 (en cours, ~90%)
- ✅ Lecture mushaf + recherche
- ✅ Audio multi-récitateurs
- ✅ Hifz (plan, masquage, test, écoute & répète)
- ✅ **FSRS v4 complet** pour la Murajaa
- ✅ Statistiques + streaks + notifications
- ⏳ ASR Tajwid (reconnaissance vocale)
- ⏳ Téléchargement offline audio
- ⏳ Tajwid coloré sur mushaf

### V2 (post-MVP)
- Halaqat virtuelles (groupes + visio)
- Coach IA conversationnel
- Tafsir multi-sources
- Backend Supabase + sync cloud

### V3
- ASR Tajwid niveau 2 (analyse phonétique fine)
- AR Mushaf
- Mode enfants

---

## 📝 Licence

Code source privé, propriété de [@sKaouech](https://github.com/sKaouech).
Le texte du Coran et ses traductions sont sous licences ouvertes.

---

## 🤝 Contact

- **Auteur** : [@sKaouech](https://github.com/sKaouech)
- **Suivi projet** : Jira [QUR](https://kaouechseifddine.atlassian.net/jira/software/projects/QUR)
- **Documentation produit** : Confluence [Nuran](https://kaouechseifddine.atlassian.net/wiki/spaces/QU/overview)

---

*« Et nous avons rendu le Coran facile à mémoriser. Y a-t-il quelqu'un pour se rappeler ? »* — Sourate Al-Qamar (54:17)
