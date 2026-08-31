# Brief pour la prochaine session

Écrit à la fin de la session du 30 août 2026, pour survivre à la compaction de
contexte et être lisible par n'importe quelle session Claude (VS Code ou web).

## Décision produit prise

Les données restent **en local sur l'iPhone**. Pas de compte, pas de synchro,
pas de dossier cloud partagé. C'est un choix assumé, pas un report par défaut.

Un **NAS personnel** arrive. Il servira alors de serveur auto-hébergé, et c'est
à ce moment-là qu'une connexion prendra son sens : ce ne sera plus « du cloud »
mais l'infrastructure de l'utilisateur. `PRODUCT.md` devra être réécrit à ce
moment-là — l'engagement « pas de cloud » deviendra « pas de serveur tiers ».

Rien à faire d'ici là : le stockage local est déjà en place, et
`LeveliaRepository` (deux méthodes, `load` / `save`) est le point d'accroche.

## Travail demandé, dans cet ordre

### 1. Refactorisation, sans rien casser

Le filet de sécurité est déjà là et doit le rester :

- Les tests du **domaine** (`leveling`, `schedule`, `streaks`, `xp_award`)
  doivent passer **sans être modifiés**. C'est ce qui prouve que le
  comportement est intact. Un test de domaine réécrit pendant un refactor
  annule la démonstration.
- Les tests d'**interface** (`app_smoke_test`) ne se réécrivent que si le
  vocabulaire de widgets change par décision, jamais par accident.
- `flutter analyze` à zéro, suite complète verte, avant de pousser.

Pistes repérées mais non traitées, à arbitrer :

- Les grands écrans (`today_screen`, `profile_screen`) mélangent encore
  composition et présentation ; des sous-widgets nommés les rendraient plus
  lisibles.
- `dart format` n'est pas passé sur `lib/state/providers.dart` ni
  `test/xp_award_test.dart` (les seuls fichiers non reformatés).
- Aucune CI n'existe : `flutter analyze` + `flutter test` + `dart format
  --set-exit-if-changed` en action GitHub éviteraient les régressions
  silencieuses entre sessions.

### 2. Introduction au premier lancement

Un accueil affiché **une seule fois**, à la toute première ouverture :

1. Un salut à l'utilisateur.
2. **Cinq écrans**, un par onglet, expliquant à quoi il sert :
   `Aujourd'hui` · `Habitudes` · `Objectifs` · `Progression` · `Profil`.

Contraintes de réalisation :

- Vocabulaire **Cupertino** comme le reste de l'application (voir
  `lib/ui/widgets/common.dart` et `modal_page.dart` pour les briques
  existantes). Pas de widget Material : `lib/` n'en importe plus aucun.
- Il faut un **drapeau de persistance** dans `AppData` (ex. `onboardingSeenAt`),
  sérialisé comme le reste, avec valeur par défaut rétrocompatible pour que les
  sauvegardes existantes ne rejouent pas l'intro.
- Prévoir « Passer » : une intro qu'on ne peut pas sauter est une intro subie.
- Le test de démarrage devra couvrir les deux cas : première ouverture (intro
  affichée) et ouvertures suivantes (intro absente).

## Deux points à trancher avec l'utilisateur

- **L'intro et les exemples se recouvrent.** `lib/data/seed.dart` crée déjà
  cinq domaines et quatre habitudes d'exemple au premier lancement. Faut-il
  garder les deux, ou l'intro remplace-t-elle les exemples ?
- **Le moment.** Cinq écrans avant d'avoir rien touché, cela se saute souvent
  sans être lu. Une alternative est de n'afficher que le salut au démarrage,
  puis d'expliquer chaque onglet à sa première visite. À voir avec
  l'utilisateur ; ne pas trancher seul.

## Pièges d'environnement déjà rencontrés

À lire avant de débugger un problème d'affichage : ils ont coûté du temps
une fois, ils n'ont pas à en coûter deux.

### Les emojis manquent sur le simulateur iOS

**Ce n'est pas un défaut de l'application.** Le runtime du simulateur
iOS 26.3 n'embarque pas la police Apple Color Emoji : iOS lui-même affiche
des carrés, y compris dans le clavier emoji de Safari. Sur un iPhone
physique, tout s'affiche correctement.

Le test qui tranche en dix secondes, avant de toucher au code : ouvrir
Safari **dans le simulateur**, afficher le clavier emoji. Carrés = le
système, pas l'app. Ce test sépare l'environnement de l'application et
doit venir en premier sur tout problème de rendu.

Deux correctifs ont été poussés avant ce test, sur de fausses pistes. Ils
sont conservés car défendables sur le fond, mais aucun n'était la cause :

- `CupertinoSystemText` / `CupertinoSystemDisplay` au lieu de `.SF Pro Text`
  codé en dur — à garder, c'est ce que le thème Cupertino de Flutter
  utilise par défaut, et `.SF Pro Text` n'existe ni sur Windows ni sur
  Android.
- `AppText.emoji(size)`, qui nomme explicitement Apple Color Emoji, Noto
  Color Emoji et Segoe UI Emoji en repli — à garder aussi : ça centralise
  le rendu des emojis en un seul endroit et sécurise Windows et Android.
  Peut être retiré si l'on veut une base plus mince.

### `--no-enable-impeller` ne fait plus rien sur iOS

Skia a été retiré d'iOS sur les Flutter récents : le drapeau est ignoré et
le log continue d'afficher `Using the Impeller rendering backend`. Ne pas
en tirer de conclusion, le test est nul et non avenu.

### Lancer sur l'iPhone physique

La signature est configurée (compte Apple gratuit, équipe personnelle dans
Xcode). Deux réglages sur le téléphone, une fois : **Mode développeur**
(Réglages → Confidentialité et sécurité) et **faire confiance au
certificat** (Réglages → Général → VPN et gestion de l'appareil).

Attention : avec un compte gratuit, **l'app expire au bout de 7 jours** et
doit être réinstallée depuis le Mac.

## État du dépôt à la fin de cette session

- `feature/ui-apple-cupertino` (`ed0ce99`) — passage complet à Cupertino.
  Basée sur `refactor/coherence-et-robustesse`.
- Quatre branches coexistent, aucune fusionnée, et la branche par défaut du
  dépôt est encore `claude/flutter-habit-tracking-app-qopymg`. Un nettoyage
  vers une branche `main` unique a été proposé et reste à faire.
- Vérifié sur Flutter 3.38.5 / Dart 3.10.4 : analyse propre, 45 tests verts,
  build Linux release exécuté.
- Deux machines en jeu (Mac et Windows) : un `.gitattributes` reste à ajouter
  pour figer les fins de ligne.
