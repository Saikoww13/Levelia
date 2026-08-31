import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/core/theme/app_theme.dart';

/// Les fichiers de fonte déclarés dans `pubspec.yaml`, par graisse.
///
/// Lecture textuelle volontaire : ajouter une dépendance YAML pour trois
/// lignes serait disproportionné, et le format de ce bloc est stable.
Map<int, String> _facesDeclarees() {
  final lignes = File('pubspec.yaml').readAsLinesSync();
  final debut = lignes.indexWhere((l) => l.trim() == '- family: $_famille');
  expect(
    debut,
    isNonNegative,
    reason: 'La famille $_famille n\'est plus déclarée dans pubspec.yaml.',
  );

  final faces = <int, String>{};
  String? actif;
  for (final ligne in lignes.skip(debut + 1)) {
    final t = ligne.trim();
    // Une nouvelle famille commence : le bloc courant est terminé.
    if (t.startsWith('- family:')) break;
    if (t.startsWith('- asset:')) actif = t.substring('- asset:'.length).trim();
    if (t.startsWith('weight:') && actif != null) {
      faces[int.parse(t.substring('weight:'.length).trim())] = actif;
    }
  }
  return faces;
}

const String _famille = 'BarlowCondensed';
const double _taille = 40.0;
const String _chiffres = '1234567890';

/// Largeur d'un texte une fois mis en page.
double _largeur(String texte, TextStyle style) {
  final peintre = TextPainter(
    text: TextSpan(text: texte, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return peintre.width;
}

void main() {
  // La police des relevés est empaquetée dans `assets/fonts` plutôt que
  // téléchargée à l'exécution. Deux choses peuvent casser sans bruit : le
  // fichier peut disparaître, ou le nom de famille peut cesser de
  // correspondre. Dans les deux cas Flutter retombe silencieusement sur la
  // police par défaut. Ces tests vérifient donc la déclaration, la présence
  // des fichiers, puis le rendu réel.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<int, String> faces;

  setUpAll(() async {
    faces = _facesDeclarees();
    // Le moteur de test substitue une fonte de largeur fixe à toutes les
    // familles : il faut charger les vrais fichiers pour mesurer quoi que ce
    // soit. Ce chargement échoue si un fichier manque ou n'est pas un TTF
    // valide, ce qui est en soi une part du test.
    final chargeur = FontLoader(_famille);
    for (final chemin in faces.values) {
      chargeur.addFont(File(chemin).readAsBytes().then(ByteData.sublistView));
    }
    await chargeur.load();
  });

  group('Police des relevés', () {
    test('les trois graisses utilisées sont déclarées et présentes', () {
      // 500, 600 et 700 sont les seules graisses demandées par AppText.
      // Demander une graisse absente ferait synthétiser un faux gras.
      expect(faces.keys.toSet(), {500, 600, 700});
      for (final chemin in faces.values) {
        expect(
          File(chemin).existsSync(),
          isTrue,
          reason: 'Fichier de fonte déclaré mais absent : $chemin',
        );
      }
    });

    test('la fonte condensée est réellement chargée', () {
      final condense = _largeur(
        _chiffres,
        AppText.readout(size: _taille, color: const Color(0xFF000000)),
      );
      final defaut = _largeur(
        _chiffres,
        const TextStyle(fontSize: _taille, fontWeight: FontWeight.w700),
      );

      // Une fonte condensée est nettement plus étroite. Si AppText.readout
      // cessait de nommer la famille, les deux largeurs se rejoindraient.
      expect(
        condense,
        lessThan(defaut * 0.75),
        reason:
            'Les relevés occupent $condense contre $defaut pour la police '
            'par défaut : $_famille ne semble pas appliquée.',
      );
    });

    test('les chiffres gardent une chasse fixe', () {
      // Sans chasse fixe, un compteur saute latéralement quand un chiffre en
      // remplace un autre.
      final style = AppText.readout(
        size: _taille,
        color: const Color(0xFF000000),
      );
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(_largeur('111', style), _largeur('888', style));
    });

    test('les étiquettes d\'unité utilisent la même famille', () {
      expect(AppText.unit(const Color(0xFF000000)).fontFamily, _famille);
    });
  });
}
