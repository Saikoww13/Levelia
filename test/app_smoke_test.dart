import 'package:flutter/cupertino.dart';
// Importé uniquement pour pouvoir affirmer l'absence de ces widgets :
// l'application, elle, ne dépend plus de Material.
import 'package:flutter/material.dart'
    show AppBar, FloatingActionButton, NavigationBar, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/app.dart';
import 'package:levelia/core/util/day.dart';
import 'package:levelia/data/json_file_repository.dart';
import 'package:levelia/data/seed.dart';
import 'package:levelia/state/providers.dart';

/// Monte l'application complète sur un dépôt en mémoire.
Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(420, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(
          InMemoryRepository(buildSeedData()),
        ),
      ],
      child: const LeveliaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(CupertinoPageScaffold).first),
);

void main() {
  testWidgets('l\'application démarre sur l\'écran du jour', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Aujourd\'hui'), findsWidgets);
    expect(find.text(longDayLabel(today())), findsOneWidget);
    // Les habitudes d'exemple attendues aujourd'hui sont listées.
    expect(find.text('Lire 10 pages'), findsOneWidget);
  });

  testWidgets('l\'interface est bien en vocabulaire Apple', (tester) async {
    await _pumpApp(tester);

    // Chrome iOS présent…
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    expect(find.byType(CupertinoSliverNavigationBar), findsWidgets);
    // …et plus aucun chrome Material.
    expect(find.byType(Scaffold), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('pointer une habitude crédite de l\'XP', (tester) async {
    await _pumpApp(tester);

    final container = _container(tester);
    expect(container.read(appDataProvider).totalXp, 0);

    await tester.tap(find.text('Lire 10 pages'));
    // On avance juste assez pour voir la bannière : `pumpAndSettle` déroulerait
    // toute son animation, jusqu'à sa disparition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // « Lire 10 pages » est une habitude facile : 10 XP, sans bonus de série.
    expect(container.read(appDataProvider).totalXp, 10);
    expect(find.textContaining('+10 XP'), findsWidgets);

    // Puis elle se retire d'elle-même, sans laisser de minuterie en suspens.
    await tester.pumpAndSettle();
    expect(find.textContaining('+10 XP'), findsNothing);
  });

  testWidgets('la navigation atteint chacun des cinq onglets', (tester) async {
    await _pumpApp(tester);

    for (final onglet in ['Habitudes', 'Objectifs', 'Progression', 'Profil']) {
      await tester.tap(find.text(onglet).last);
      await tester.pumpAndSettle();
      expect(
        find.text(onglet),
        findsWidgets,
        reason: 'l\'onglet $onglet doit s\'afficher',
      );
    }
  });

  testWidgets('sur grand écran, la navigation passe en barre latérale', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1280, 900));

    // Apple ne descend pas les onglets en bas d'une grande fenêtre.
    expect(find.byType(CupertinoTabBar), findsNothing);
    expect(find.text('Levelia'), findsOneWidget);
    expect(find.text('Progression'), findsWidgets);
  });

  testWidgets('créer une habitude l\'ajoute à la journée', (tester) async {
    // Fenêtre haute : le formulaire tient d'un seul tenant, ce qui évite de
    // piloter le défilement de la page modale dans le test.
    await _pumpApp(tester, size: const Size(500, 1700));

    await tester.tap(find.byIcon(CupertinoIcons.add).first);
    await tester.pumpAndSettle();

    // Le formulaire s'ouvre en page modale, avec Annuler / Créer dans la barre.
    expect(find.text('Nouvelle habitude'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);

    await tester.enterText(
      find.byType(CupertinoTextField).first,
      'Boire 2 litres d\'eau',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // La page s'est refermée et l'habitude apparaît dans la journée.
    expect(find.text('Nouvelle habitude'), findsNothing);
    expect(find.text('Boire 2 litres d\'eau'), findsOneWidget);

    expect(
      _container(tester).read(appDataProvider).activeHabits.map((h) => h.title),
      contains('Boire 2 litres d\'eau'),
    );
  });

  testWidgets(
    'l\'action de validation reste inactive tant que le titre est vide',
    (tester) async {
      await _pumpApp(tester, size: const Size(500, 1700));

      await tester.tap(find.byIcon(CupertinoIcons.add).first);
      await tester.pumpAndSettle();

      // Sur iOS on désactive l'action plutôt que d'afficher une erreur après coup.
      final creer = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text('Créer'),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(creer.onPressed, isNull);
    },
  );
}
