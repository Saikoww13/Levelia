import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/app.dart';
import 'package:levelia/core/util/day.dart';
import 'package:levelia/data/json_file_repository.dart';
import 'package:levelia/data/seed.dart';
import 'package:levelia/state/providers.dart';

/// Monte l'application complète sur un dépôt en mémoire.
Future<void> _pumpApp(WidgetTester tester, {Size size = const Size(420, 900)}) async {
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

void main() {
  testWidgets('l\'application démarre sur l\'écran du jour', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Aujourd\'hui'), findsWidgets);
    expect(find.text(longDayLabel(today())), findsOneWidget);
    // Les habitudes d'exemple attendues aujourd'hui sont listées.
    expect(find.text('Lire 10 pages'), findsOneWidget);
  });

  testWidgets('pointer une habitude crédite de l\'XP', (tester) async {
    await _pumpApp(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    expect(container.read(appDataProvider).totalXp, 0);

    await tester.tap(find.text('Lire 10 pages'));
    await tester.pumpAndSettle();

    // « Lire 10 pages » est une habitude facile : 10 XP, sans bonus de série.
    expect(container.read(appDataProvider).totalXp, 10);
    expect(find.textContaining('+10 XP'), findsWidgets);
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

  testWidgets('sur grand écran, la navigation passe en rail latéral', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(1280, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('créer une habitude l\'ajoute à la journée', (tester) async {
    // Fenêtre haute : le formulaire de création tient alors d'un seul tenant,
    // ce qui évite de piloter le défilement de la feuille modale dans le test.
    await _pumpApp(tester, size: const Size(500, 1700));

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Habitude'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Intitulé'),
      'Boire 2 litres d\'eau',
    );

    final valider = find.widgetWithText(FilledButton, 'Créer');
    await tester.tap(valider);
    await tester.pumpAndSettle();

    // La feuille s'est refermée et l'habitude apparaît dans la journée.
    expect(valider, findsNothing);
    expect(find.text('Boire 2 litres d\'eau'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    expect(
      container.read(appDataProvider).activeHabits.map((h) => h.title),
      contains('Boire 2 litres d\'eau'),
    );
  });
}
