import 'dart:math' as math;

/// Moteur de progression : conversion XP <-> niveau.
///
/// La courbe est volontairement simple et lisible : franchir le niveau `n`
/// demande `baseXp + (n - 1) * step` points. Les premiers niveaux tombent vite
/// (effet de récompense immédiat), puis l'écart se creuse linéairement.
class Leveling {
  const Leveling._();

  /// XP demandée pour passer du niveau [level] au niveau suivant.
  static const int baseXp = 100;
  static const int step = 50;

  /// Niveau maximum affichable. Au-delà, l'XP continue d'être comptée mais le
  /// niveau plafonne (évite une boucle infinie sur des valeurs aberrantes).
  static const int maxLevel = 999;

  /// XP nécessaire pour franchir le niveau [level] (>= 1).
  static int xpToAdvance(int level) {
    final l = math.max(1, level);
    return baseXp + (l - 1) * step;
  }

  /// XP cumulée totale nécessaire pour *atteindre* le niveau [level].
  ///
  /// Le niveau 1 est le point de départ et coûte 0.
  static int cumulativeXpFor(int level) {
    final l = math.max(1, level);
    final n = l - 1;
    // Somme arithmétique : n * baseXp + step * (0 + 1 + ... + (n - 1)).
    return n * baseXp + step * (n * (n - 1)) ~/ 2;
  }

  /// Décrit la progression correspondant à [totalXp].
  static LevelInfo describe(int totalXp) {
    final xp = math.max(0, totalXp);
    var level = 1;
    var consumed = 0;

    while (level < maxLevel) {
      final needed = xpToAdvance(level);
      if (xp - consumed < needed) break;
      consumed += needed;
      level++;
    }

    final into = xp - consumed;
    final needed = level >= maxLevel ? 0 : xpToAdvance(level);

    return LevelInfo(
      level: level,
      totalXp: xp,
      xpIntoLevel: into,
      xpForNextLevel: needed,
    );
  }

  /// Titre honorifique associé à un niveau, façon fiche de personnage.
  static String rankFor(int level) {
    if (level >= 60) return 'Légende';
    if (level >= 45) return 'Grand maître';
    if (level >= 32) return 'Maître';
    if (level >= 22) return 'Expert';
    if (level >= 14) return 'Adepte';
    if (level >= 8) return 'Initié';
    if (level >= 4) return 'Apprenti';
    return 'Novice';
  }
}

/// Photographie d'une progression : niveau atteint et avancement dans celui-ci.
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  /// Niveau atteint (commence à 1).
  final int level;

  /// XP cumulée depuis toujours.
  final int totalXp;

  /// XP engrangée à l'intérieur du niveau courant.
  final int xpIntoLevel;

  /// XP totale requise pour franchir le niveau courant. 0 si niveau maximum.
  final int xpForNextLevel;

  /// Avancement dans le niveau courant, entre 0 et 1.
  double get progress {
    if (xpForNextLevel <= 0) return 1;
    return (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);
  }

  /// XP restante avant le niveau suivant.
  int get xpRemaining => math.max(0, xpForNextLevel - xpIntoLevel);

  /// Titre honorifique du niveau courant.
  String get rank => Leveling.rankFor(level);
}
