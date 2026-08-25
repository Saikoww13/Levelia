import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/domain/engine/leveling.dart';

void main() {
  group('Leveling', () {
    test('le premier niveau demande l\'XP de base', () {
      expect(Leveling.xpToAdvance(1), 100);
      expect(Leveling.xpToAdvance(2), 150);
      expect(Leveling.xpToAdvance(3), 200);
    });

    test('l\'XP cumulée suit la somme des paliers', () {
      expect(Leveling.cumulativeXpFor(1), 0);
      expect(Leveling.cumulativeXpFor(2), 100);
      expect(Leveling.cumulativeXpFor(3), 250);
      expect(Leveling.cumulativeXpFor(4), 450);
    });

    test('un compte neuf est niveau 1 sans progression', () {
      final info = Leveling.describe(0);
      expect(info.level, 1);
      expect(info.xpIntoLevel, 0);
      expect(info.xpForNextLevel, 100);
      expect(info.progress, 0);
    });

    test('describe et cumulativeXpFor sont cohérents à chaque palier', () {
      for (var niveau = 1; niveau <= 30; niveau++) {
        final seuil = Leveling.cumulativeXpFor(niveau);
        expect(
          Leveling.describe(seuil).level,
          niveau,
          reason: 'le seuil exact du niveau $niveau doit y donner accès',
        );
        expect(
          Leveling.describe(seuil - 1).level,
          niveau - 1 < 1 ? 1 : niveau - 1,
          reason: 'un point en dessous, on reste au niveau précédent',
        );
      }
    });

    test('la progression dans un niveau est correctement rapportée', () {
      // 100 XP pour finir le niveau 1, puis 75 des 150 du niveau 2.
      final info = Leveling.describe(175);
      expect(info.level, 2);
      expect(info.xpIntoLevel, 75);
      expect(info.xpForNextLevel, 150);
      expect(info.progress, 0.5);
      expect(info.xpRemaining, 75);
    });

    test('une XP négative est ramenée à zéro', () {
      expect(Leveling.describe(-500).level, 1);
      expect(Leveling.describe(-500).totalXp, 0);
    });

    test('les rangs montent avec le niveau', () {
      expect(Leveling.rankFor(1), 'Novice');
      expect(Leveling.rankFor(5), 'Apprenti');
      expect(Leveling.rankFor(60), 'Légende');
    });
  });
}
