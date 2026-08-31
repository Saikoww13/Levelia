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
import 'package:levelia/domain/models/app_data.dart';
import 'package:levelia/domain/models/category.dart';
import 'package:levelia/domain/models/habit.dart';
import 'package:levelia/state/providers.dart';

/// Un état déjà installé : introduction vue, un domaine, une habitude.
///
/// Les tests ne s'appuient plus sur `seed.dart`, qui ne crée plus rien : c'est
/// désormais l'introduction qui fait créer le premier contenu.
AppData _installe() => AppData(
  onboardingSeenAt: DateTime(2026),
  categories: const [
    Category(id: 'c1', name: 'Esprit', emoji: '🧠', colorValue: 0xFF7C4DFF),
  ],
  habits: [
    Habit(
      id: 'h1',
      title: 'Lire 10 pages',
      categoryId: 'c1',
      difficulty: HabitDifficulty.easy,
      createdAt: today(),
    ),
  ],
);

Future<void> _pumpApp(
  WidgetTester tester, {
  AppData? depart,
  Size size = const Size(420, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(
          InMemoryRepository(depart ?? _installe()),
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
  group('Introduction', () {
    testWidgets('la première ouverture affiche l\'introduction', (
      tester,
    ) async {
      await _pumpApp(tester, depart: const AppData());

      expect(find.text('Bienvenue dans Levelia'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
      // Les onglets ne sont pas encore accessibles.
      expect(find.byType(CupertinoTabBar), findsNothing);
    });

    testWidgets('une fois vue, elle ne réapparaît plus', (tester) async {
      await _pumpApp(tester);

      expect(find.text('Bienvenue dans Levelia'), findsNothing);
      expect(find.byType(CupertinoTabBar), findsOneWidget);
    });

    testWidgets('« Passer » referme l\'introduction sans rien créer', (
      tester,
    ) async {
      await _pumpApp(tester, depart: const AppData());

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      final data = _container(tester).read(appDataProvider);
      expect(data.needsOnboarding, isFalse);
      expect(data.categories, isEmpty);
      expect(find.byType(CupertinoTabBar), findsOneWidget);
    });

    testWidgets('les cinq onglets sont expliqués, un écran chacun', (
      tester,
    ) async {
      await _pumpApp(tester, depart: const AppData());

      for (final titre in [
        'Aujourd\'hui',
        'Habitudes',
        'Objectifs',
        'Progression',
        'Profil',
      ]) {
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();
        expect(
          find.text(titre),
          findsOneWidget,
          reason: 'l\'écran de $titre doit être présenté',
        );
      }
    });

    testWidgets('le dernier écran crée le domaine et la première habitude', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        depart: const AppData(),
        size: const Size(500, 1700),
      );

      // Six appuis mènent du salut jusqu'à l'écran de création.
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();
      }
      expect(find.text('On commence'), findsOneWidget);

      // Tant qu'aucun domaine n'est choisi, on ne peut pas valider.
      final commencer = find.widgetWithText(CupertinoButton, 'Commencer');
      expect(tester.widget<CupertinoButton>(commencer).onPressed, isNull);

      await tester.tap(find.text('Esprit'));
      await tester.pumpAndSettle();
      // Une idée d'habitude proposée remplit le champ d'un appui.
      await tester.tap(find.text('Lire 10 pages'));
      await tester.pumpAndSettle();

      await tester.tap(commencer);
      await tester.pumpAndSettle();

      final data = _container(tester).read(appDataProvider);
      expect(data.needsOnboarding, isFalse);
      expect(data.categories.single.name, 'Esprit');
      expect(data.activeHabits.single.title, 'Lire 10 pages');
      expect(
        data.activeHabits.single.categoryId,
        data.categories.single.id,
        reason: 'l\'habitude doit rejoindre le domaine choisi',
      );
      expect(find.byType(CupertinoTabBar), findsOneWidget);
    });

    testWidgets('« Revoir l\'introduction » la rejoue', (tester) async {
      await _pumpApp(tester, size: const Size(500, 1700));

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoir l\'introduction'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue dans Levelia'), findsOneWidget);
      // Rien n'a été effacé au passage.
      final data = _container(tester).read(appDataProvider);
      expect(data.categories, hasLength(1));
      expect(data.activeHabits, hasLength(1));
    });
  });

  group('Application', () {
    testWidgets('démarre sur l\'écran du jour', (tester) async {
      await _pumpApp(tester);

      expect(find.text('Aujourd\'hui'), findsWidgets);
      expect(find.text(longDayLabel(today())), findsOneWidget);
      expect(find.text('Lire 10 pages'), findsOneWidget);
    });

    testWidgets('l\'interface est bien en vocabulaire Apple', (tester) async {
      await _pumpApp(tester);

      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(find.byType(CupertinoSliverNavigationBar), findsWidgets);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Habitude facile : 10 XP, sans bonus de série.
      expect(container.read(appDataProvider).totalXp, 10);
      expect(find.textContaining('+10 XP'), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.textContaining('+10 XP'), findsNothing);
    });

    testWidgets('la navigation atteint chacun des cinq onglets', (
      tester,
    ) async {
      await _pumpApp(tester);

      for (final onglet in [
        'Habitudes',
        'Objectifs',
        'Progression',
        'Profil',
      ]) {
        await tester.tap(find.text(onglet).last);
        await tester.pumpAndSettle();
        expect(find.text(onglet), findsWidgets);
      }
    });

    testWidgets('sur grand écran, la navigation passe en barre latérale', (
      tester,
    ) async {
      await _pumpApp(tester, size: const Size(1280, 900));

      expect(find.byType(CupertinoTabBar), findsNothing);
      expect(find.text('Levelia'), findsOneWidget);
    });

    testWidgets('créer une habitude l\'ajoute à la journée', (tester) async {
      await _pumpApp(tester, size: const Size(500, 1700));

      await tester.tap(find.byIcon(CupertinoIcons.add).first);
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle habitude'), findsOneWidget);

      await tester.enterText(
        find.byType(CupertinoTextField).first,
        'Boire 2 litres d\'eau',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle habitude'), findsNothing);
      expect(find.text('Boire 2 litres d\'eau'), findsOneWidget);
    });

    testWidgets(
      'l\'action de validation reste inactive tant que le titre est vide',
      (tester) async {
        await _pumpApp(tester, size: const Size(500, 1700));

        await tester.tap(find.byIcon(CupertinoIcons.add).first);
        await tester.pumpAndSettle();

        final creer = tester.widget<CupertinoButton>(
          find.ancestor(
            of: find.text('Créer'),
            matching: find.byType(CupertinoButton),
          ),
        );
        expect(creer.onPressed, isNull);
      },
    );
  });
}
