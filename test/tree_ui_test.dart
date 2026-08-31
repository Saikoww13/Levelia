import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/app.dart';
import 'package:levelia/core/util/day.dart';
import 'package:levelia/data/json_file_repository.dart';
import 'package:levelia/domain/models/app_data.dart';
import 'package:levelia/domain/models/category.dart';
import 'package:levelia/domain/models/habit.dart';
import 'package:levelia/domain/models/reward.dart';
import 'package:levelia/state/providers.dart';
import 'package:levelia/ui/widgets/level_up.dart';

AppData _base({int xp = 0, List<Reward> rewards = const []}) => AppData(
  onboardingSeenAt: DateTime(2026),
  categories: [
    Category(
      id: 'c1',
      name: 'Corps',
      emoji: '💪',
      colorValue: 0xFFFF7043,
      xp: xp,
    ),
  ],
  habits: [
    Habit(
      id: 'h1',
      title: 'Pompes',
      categoryId: 'c1',
      difficulty: HabitDifficulty.normal,
      createdAt: today().subtract(const Duration(days: 30)),
    ),
  ],
  rewards: rewards,
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
          InMemoryRepository(depart ?? _base()),
        ),
      ],
      child: const LeveliaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CupertinoApp)));

Future<void> _ouvrirArbre(WidgetTester tester) async {
  await tester.tap(find.text('Arbre').last);
  await tester.pumpAndSettle();
}

void main() {
  group('Onglet Arbre', () {
    testWidgets('le tronc et chaque domaine ont leur branche', (tester) async {
      await _pumpApp(tester);
      await _ouvrirArbre(tester);

      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Corps'), findsWidgets);
    });

    testWidgets('une récompense posée s\'affiche sur son palier', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        depart: _base(
          rewards: const [
            Reward(
              id: 'r1',
              level: 3,
              title: 'M\'offrir ce jeu',
              categoryId: 'c1',
            ),
          ],
        ),
      );
      await _ouvrirArbre(tester);

      expect(find.text('M\'offrir ce jeu'), findsOneWidget);
    });

    testWidgets('toucher un palier vide permet d\'y accrocher un texte', (
      tester,
    ) async {
      await _pumpApp(tester, size: const Size(420, 1400));
      await _ouvrirArbre(tester);

      // Le premier palier de la branche globale : niveau 2, encore vierge.
      await tester.tap(find.text('Niveau 2').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CupertinoTextField), 'Un bon resto');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final recompense = _container(tester).read(appDataProvider).rewards;
      expect(recompense, hasLength(1));
      expect(recompense.single.title, 'Un bon resto');
      expect(recompense.single.level, 2);
      // Palier touché sur la branche du tronc : pas de domaine porteur.
      expect(recompense.single.categoryId, isNull);
    });

    testWidgets('une récompense qui attend est signalée en tête', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        depart: _base(
          xp: 250,
          rewards: const [
            Reward(id: 'r1', level: 2, title: 'Un jeu', categoryId: 'c1'),
          ],
        ),
      );
      await _ouvrirArbre(tester);

      expect(find.text('Une récompense t\'attend'), findsOneWidget);
    });
  });

  group('Célébration de passage de niveau', () {
    testWidgets('cocher une habitude qui fait monter ouvre la carte', (
      tester,
    ) async {
      // 85 XP : les 15 XP du pointage franchissent le palier des 100.
      await _pumpApp(tester, depart: _base(xp: 85));

      await tester.tap(find.text('Pompes'));
      await tester.pumpAndSettle();

      expect(find.text('Niveau 2'), findsOneWidget);
      expect(find.text(encouragementFor(2)), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
    });

    testWidgets('la récompense du palier apparaît dans la carte', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        depart: _base(
          xp: 85,
          rewards: const [
            Reward(
              id: 'r1',
              level: 2,
              title: 'M\'offrir ce jeu Steam',
              categoryId: 'c1',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Pompes'));
      await tester.pumpAndSettle();

      expect(find.text('TA RÉCOMPENSE'), findsOneWidget);
      expect(find.text('M\'offrir ce jeu Steam'), findsOneWidget);

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('TA RÉCOMPENSE'), findsNothing);
    });

    testWidgets('un pointage sans montée n\'ouvre pas de carte', (
      tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Pompes'));
      await tester.pumpAndSettle();

      // La bannière d'XP suffit : rien qui demande une action de fermeture.
      expect(find.text('Continuer'), findsNothing);
    });

    testWidgets('la carte annonce les deux branches quand toutes montent', (
      tester,
    ) async {
      await _pumpApp(tester, depart: _base(xp: 85));

      await tester.tap(find.text('Pompes'));
      await tester.pumpAndSettle();

      // Le domaine passe devant, le tronc est rappelé en dessous.
      expect(find.text('Corps'), findsWidgets);
      expect(find.text('Global passe niveau 2'), findsOneWidget);
    });
  });
}
