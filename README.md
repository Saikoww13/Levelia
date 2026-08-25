# Levelia ⚔️

Application de développement personnel en Flutter : tu suis tes **habitudes**,
tu poursuis des **objectifs**, et chaque effort rapporte de l'**XP** à l'un de
tes **domaines de vie**, qui monte en niveau comme une fiche de personnage.

Un seul code Dart, cinq plateformes : **Android, iOS, Windows, macOS, Linux**.

---

## Ce que fait l'application

### Les habitudes

Deux natures, selon ce que tu cherches à changer :

| Nature | Journée réussie quand… | Exemple |
|---|---|---|
| **À faire** | tu l'as faite | « Lire 10 pages » |
| **À éviter** | tu n'as pas craqué | « Pas de réseaux sociaux le matin » |

Trois rythmes possibles : **tous les jours**, **certains jours de la semaine**,
ou **N fois par semaine** (le rythme souple : aucun jour n'est imposé, c'est le
total hebdomadaire qui compte).

Chaque journée se pointe en trois états, par simple appui :

```
non renseigné  →  réussi  →  manqué  →  non renseigné
```

« Manqué » est bien distinct de « pas encore pointé » : c'est une information
utile, pas un trou dans les données.

### La progression

Chaque catégorie possède **sa propre cagnotte d'XP, donc son propre niveau**.
Le **niveau global** est calculé sur la somme de toutes les catégories — tu vois
d'un coup d'œil quel domaine tu délaisses.

**Le barème** (`lib/domain/engine/xp_rules.dart`, tout est réglable au même endroit) :

| Action | XP |
|---|---|
| Habitude facile / normale / exigeante | 10 / 15 / 25 |
| Bonus de série | +2 par jour déjà tenu, plafonné à +20 |
| Étape d'objectif franchie | 20 |
| Objectif atteint | 100 |

**La courbe de niveau** : franchir le niveau `n` demande `100 + (n-1) × 50` XP.
Les premiers niveaux tombent vite, puis l'écart se creuse. Des titres
accompagnent la montée : Novice → Apprenti → Initié → Adepte → Expert → Maître →
Grand maître → Légende.

Un point de conception qui compte : **chaque pointage mémorise l'XP qu'il a
réellement rapportée**. Décocher une journée reprend exactement ce qui avait été
accordé, même si le bonus de série a changé depuis. Pas de dérive du compteur.

### Les séries

- Habitudes à jour fixe → série **en jours**, les jours non planifiés sont ignorés.
- Habitudes « N fois par semaine » → série **en semaines** réussies.
- **Sursis** : la journée (ou la semaine) en cours ne casse jamais la série tant
  qu'elle n'est pas jouée.

### Les objectifs

Un titre, un « pourquoi », une catégorie, une échéance facultative, et autant
d'étapes que nécessaire. L'avancement se déduit des étapes cochées. L'échéance
s'affiche en clair : « Dans 5 jours », « C'est aujourd'hui », « En retard de 3 j ».

### La progression visible

- **Grille de régularité** sur 16 semaines, une case par jour, teintée selon la
  part d'habitudes tenues.
- **Histogramme d'XP** sur 14 jours.
- Compteurs : XP totale, niveau, meilleure série, taux de réussite sur 30 jours.
- Niveau détaillé par domaine.

Les deux graphiques sont dessinés au `CustomPainter` — aucune bibliothèque de
charting à maintenir sur cinq plateformes.

---

## Démarrer

**Flutter 3.38 minimum** (Dart 3.9+). Vérifie avec `flutter --version` ; si ta
version est plus ancienne, `flutter upgrade` suffit.

```bash
flutter pub get
flutter run            # -d windows | macos | linux | <appareil Android/iOS>
```

Vérifications :

```bash
flutter analyze        # 0 problème
flutter test           # 39 tests
```

Le projet est vérifié sur deux SDK : **Flutter 3.38.5 / Dart 3.10.4** et
**Flutter 3.47.1 / Dart 3.13.1** — analyse propre, 39 tests verts et build
release réussi sur les deux.

> Si tu changes de version de Flutter sur un dépôt déjà compilé, lance
> `flutter clean` avant : un cache de build laissé par l'autre version fait
> échouer les tests sur un shader (`ink_sparkle.frag`) sans rapport avec le code.

---

## Architecture

```
lib/
├── core/
│   ├── theme/          Thème Material 3, clair et sombre
│   └── util/day.dart   Journées normalisées à minuit, clés `yyyy-MM-dd`
├── domain/             Dart pur, sans Flutter ni stockage — entièrement testé
│   ├── models/         Category, Habit, HabitLog, Goal, AppData
│   └── engine/         leveling · xp_rules · streaks
├── data/
│   ├── repository.dart         L'interface — le reste du code ne connaît qu'elle
│   ├── json_file_repository.dart  Stockage local, écriture atomique
│   └── seed.dart               État du premier lancement
├── state/              Riverpod : AppController + providers dérivés
└── ui/                 Un dossier par écran
```

**Le flux** : toute mutation passe par `AppController`, qui transforme un
`AppData` immuable et persiste dans la foulée. L'interface ne fait que lire des
providers et appeler le contrôleur — elle ne calcule jamais d'XP elle-même.

### Le stockage, et la synchro à venir

Aujourd'hui : **tout est local**, dans un unique fichier JSON du dossier de
données de l'application. Écriture atomique (fichier temporaire puis renommage),
donc jamais de JSON tronqué si l'app est tuée en plein enregistrement. Un fichier
illisible est mis de côté plutôt que perdu silencieusement.

Ce choix évite toute dépendance native à compiler sur cinq plateformes, et le
volume s'y prête largement (quelques milliers de pointages).

**Pour brancher le cloud plus tard**, il suffit d'une seconde implémentation de
`LeveliaRepository` (deux méthodes, `load` et `save`) et de la substituer dans
`repositoryProvider`. Ni le domaine ni l'interface n'ont à bouger. `AppData`
porte déjà un `schemaVersion` et un `updatedAt` pour arbitrer les conflits, et
son JSON est directement utilisable comme charge utile.

En attendant, **Profil → Exporter une sauvegarde** copie tout l'état dans le
presse-papiers, et l'import le restaure.

---

## Tests

39 tests couvrent ce qui doit rester juste :

| Fichier | Ce qui est vérifié |
|---|---|
| `leveling_test.dart` | Courbe d'XP, seuils de niveau, rangs, XP négative |
| `schedule_test.dart` | Les trois rythmes, libellés, sérialisation |
| `streaks_test.dart` | Séries en jours et en semaines, sursis, jours non planifiés |
| `xp_award_test.dart` | Barème, cycle de pointage, **reprise exacte de l'XP**, objectifs, export/import |
| `app_smoke_test.dart` | Démarrage, pointage bout en bout, navigation, bascule mobile/bureau, création d'habitude |

---

## Adapter à ton usage

| Envie | Où toucher |
|---|---|
| Changer le barème d'XP | `lib/domain/engine/xp_rules.dart` |
| Rendre les niveaux plus longs | `Leveling.baseXp` / `Leveling.step` |
| Renommer les rangs | `Leveling.rankFor` |
| Changer les catégories de départ | `lib/data/seed.dart` |
| Changer la couleur d'accent | `AppTheme.seed` |

---

## Ce qui n'est pas là

Choisi sciemment, pour livrer un socle solide plutôt qu'une ébauche large :

- **Rappels et notifications** — demande une configuration native par
  plateforme (permissions, canaux Android, entitlements iOS).
- **Synchro cloud** — l'architecture l'accueille, l'implémentation reste à écrire.
- **Habitudes quantifiées** (« 50 pompes », « 2 L d'eau ») et **de durée** —
  `HabitPolarity` et le pointage sont prêts à s'étendre.
- **Badges et succès** — l'XP et les séries fournissent déjà toute la matière.
