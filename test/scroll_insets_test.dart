import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart' show RenderSliverList;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/app.dart';
import 'package:levelia/core/theme/app_theme.dart';
import 'package:levelia/data/json_file_repository.dart';
import 'package:levelia/domain/models/app_data.dart';
import 'package:levelia/domain/models/category.dart';
import 'package:levelia/domain/models/goal.dart';
import 'package:levelia/domain/models/habit.dart';
import 'package:levelia/state/providers.dart';
import 'package:levelia/ui/widgets/common.dart';

/// Hauteur de l'indicateur d'accueil d'un iPhone récent.
const double _indicateur = 34;

/// Hauteur d'une `CupertinoTabBar`, constante privée côté Flutter.
const double _barre = 50;

const Size _ecran = Size(402, 874);

/// Zone basse masquée par la barre d'onglets translucide.
const double _obstruction = _barre + _indicateur;

void _regleEcran(WidgetTester tester) {
  tester.view.physicalSize = _ecran;
  tester.view.devicePixelRatio = 1.0;
  // Un iPhone à encoche : la barre d'onglets se pose au-dessus de
  // l'indicateur d'accueil, et le contenu passe sous les deux.
  tester.view.padding = const FakeViewPadding(bottom: _indicateur);
  tester.view.viewPadding = const FakeViewPadding(bottom: _indicateur);
  addTearDown(tester.view.reset);
}

/// Fait défiler la liste principale jusqu'à sa toute fin, et renvoie la
/// hauteur de contenu qui dépassait de l'écran.
Future<double> _jusquEnBas(WidgetTester tester) async {
  final ScrollableState liste = tester.state(
    find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  final double course = liste.position.maxScrollExtent;
  liste.position.jumpTo(course);
  await tester.pumpAndSettle();
  return course;
}

/// Ordonnée du bas du dernier élément de la liste, en coordonnées écran.
///
/// On interroge la `SliverList` elle-même plutôt que de chercher un widget
/// par son type : un `find` qui ne trouve rien rendrait le test complaisant.
double _basDuContenu(WidgetTester tester) {
  // La première SliverList sous la CustomScrollView est celle de la page :
  // l'écran du jour en contient une seconde, horizontale, pour la bande des
  // jours de la semaine.
  final RenderSliverList liste = tester.renderObject(
    find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(SliverList),
        )
        .first,
  );
  final RenderBox? dernier = liste.lastChild;
  expect(dernier, isNotNull, reason: 'La liste ne rend aucun élément.');
  return dernier!.localToGlobal(Offset(0, dernier.size.height)).dy;
}

/// Le bas utile de l'écran : en dessous, la barre d'onglets recouvre tout.
double get _basUtile => _ecran.height - _obstruction;

AppData _donnees() => AppData(
  onboardingSeenAt: DateTime(2026),
  categories: const [
    Category(id: 'c1', name: 'Esprit', emoji: '🧠', colorValue: 0xFF7C4DFF),
  ],
  habits: [
    for (var i = 0; i < 8; i++)
      Habit(
        id: 'h$i',
        title: 'Habitude $i',
        categoryId: 'c1',
        difficulty: HabitDifficulty.easy,
        createdAt: DateTime(2026),
      ),
  ],
  goals: [
    for (var i = 0; i < 12; i++)
      Goal(
        id: 'g$i',
        title: 'Objectif $i',
        categoryId: 'c1',
        createdAt: DateTime(2026),
      ),
  ],
);

void main() {
  // La barre d'onglets de Levelia est translucide. Flutter fait alors passer
  // le contenu dessous et signale la zone masquée par `MediaQuery.padding` :
  // c'est à la page d'ajouter cette marge. Une marge basse fixe laisse donc
  // le dernier élément définitivement sous la barre, hors d'atteinte.
  group('Défilement jusqu\'en bas', () {
    testWidgets('la barre d\'onglets est bien translucide', (tester) async {
      // Si elle devenait opaque, Flutter décalerait le contenu lui-même et
      // les tests suivants ne prouveraient plus rien.
      expect(AppTheme.bar.color.a, lessThan(1.0));
      expect(AppTheme.bar.darkColor.a, lessThan(1.0));
    });

    testWidgets('le dernier élément d\'une AppPage se dégage de la barre', (
      tester,
    ) async {
      _regleEcran(tester);
      const derniere = ValueKey('derniere');

      await tester.pumpWidget(
        CupertinoApp(
          theme: AppTheme.theme(Brightness.light),
          home: CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              backgroundColor: AppTheme.bar,
              items: const [
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.circle)),
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.square)),
              ],
            ),
            tabBuilder: (_, _) => AppPage(
              title: 'Essai',
              children: [
                for (var i = 0; i < 20; i++)
                  SizedBox(height: 60, child: Text('ligne $i')),
                const SizedBox(key: derniere, height: 60),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _jusquEnBas(tester);

      expect(
        tester.getRect(find.byKey(derniere)).bottom,
        lessThanOrEqualTo(_basUtile),
        reason:
            'Le dernier élément reste sous la barre d\'onglets : on ne peut '
            'pas le faire remonter en défilant.',
      );
    });

    for (final onglet in [
      'Aujourd\'hui',
      'Habitudes',
      'Objectifs',
      'Progression',
      'Arbre',
      'Profil',
    ]) {
      testWidgets('l\'onglet $onglet se déroule jusqu\'au bout', (
        tester,
      ) async {
        _regleEcran(tester);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(
                InMemoryRepository(_donnees()),
              ),
            ],
            child: const LeveliaApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(onglet).last);
        await tester.pumpAndSettle();
        final double course = await _jusquEnBas(tester);

        // Sans contenu qui dépasse, l'écran n'a rien à faire défiler et le
        // test ne prouverait rien : le jeu de données doit rester copieux.
        expect(
          course,
          greaterThan(0),
          reason: 'L\'onglet « $onglet » tient dans l\'écran : test creux.',
        );

        final double bas = _basDuContenu(tester);
        expect(
          bas,
          lessThanOrEqualTo(_basUtile),
          reason:
              'Sur « $onglet », le contenu descend jusqu\'à $bas alors que '
              'la barre d\'onglets commence à $_basUtile.',
        );
      });
    }
  });
}
