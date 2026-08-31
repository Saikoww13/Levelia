import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Icônes Cupertino dont le rendu a été constaté de visu dans l'application.
///
/// La liste n'est pas décorative. `cupertino_icons` déclare côté Dart bien
/// plus d'icônes que sa police ne sait dessiner : `CupertinoIcons.gift`,
/// `star` ou `hexagon` compilent sans broncher et sortent en carré tofu.
/// Pire, `CupertinoIcons.tree` tombe sur U+F91D, qui appartient au bloc des
/// idéogrammes de compatibilité CJK : l'onglet affichait « 欄 ».
///
/// Lire la police pour trancher ne marche pas — sa table de correspondance
/// annonce des glyphes que le moteur ne dessine pas. Seul l'œil décide. Cette
/// liste consigne donc ce qui a été vérifié à l'écran ; si un test échoue
/// parce qu'une icône nouvelle s'y ajoute, il faut la regarder tourner avant
/// de l'inscrire ici.
const Set<String> iconesVerifiees = {
  'add',
  'arrow_counterclockwise',
  'bolt_fill',
  'book',
  'chart_bar',
  'chart_bar_fill',
  'chart_pie_fill',
  'check_mark',
  'checkmark_circle',
  'checkmark_circle_fill',
  'chevron_down',
  'chevron_forward',
  'chevron_left',
  'chevron_right',
  'chevron_up',
  'circle',
  'clear_circled_solid',
  'ellipsis',
  'exclamationmark_triangle',
  'flag',
  'flag_fill',
  'flame_fill',
  'minus_circle',
  'nosign',
  'pencil',
  'person',
  'person_fill',
  'rosette',
  'sparkles',
  'square_arrow_down',
  'square_arrow_up',
  'square_list',
  'square_list_fill',
  'xmark_circle_fill',
};

/// Toutes les icônes Cupertino nommées dans `lib/`.
Set<String> _iconesUtilisees() {
  final motif = RegExp(r'CupertinoIcons\.([a-z_0-9]+)');
  final trouvees = <String>{};

  for (final entite in Directory('lib').listSync(recursive: true)) {
    if (entite is! File || !entite.path.endsWith('.dart')) continue;
    for (final m in motif.allMatches(entite.readAsStringSync())) {
      trouvees.add(m.group(1)!);
    }
  }
  return trouvees;
}

void main() {
  test('toute icône employée a été vue à l\'écran', () {
    final inconnues = _iconesUtilisees().difference(iconesVerifiees);

    expect(
      inconnues,
      isEmpty,
      reason:
          'Icônes non vérifiées : $inconnues. Lance l\'application et regarde '
          'qu\'elles se dessinent avant de les ajouter à iconesVerifiees — '
          'une icône absente de la police sort en carré, sans la moindre '
          'erreur de compilation.',
    );
  });

  test('la liste vérifiée ne garde pas d\'icône abandonnée', () {
    // Une entrée qui ne sert plus finirait par légitimer une icône jamais
    // regardée, le jour où quelqu'un la réemploie.
    expect(iconesVerifiees.difference(_iconesUtilisees()), isEmpty);
  });
}
