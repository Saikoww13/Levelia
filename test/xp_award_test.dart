import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/core/util/day.dart';
import 'package:levelia/data/json_file_repository.dart';
import 'package:levelia/domain/engine/xp_rules.dart';
import 'package:levelia/domain/models/app_data.dart';
import 'package:levelia/domain/models/category.dart';
import 'package:levelia/domain/models/goal.dart';
import 'package:levelia/domain/models/habit.dart';
import 'package:levelia/state/app_controller.dart';
import 'package:levelia/state/providers.dart';

/// Un état de départ maîtrisé : une catégorie vide, une habitude quotidienne.
AppData _base() => AppData(
  categories: const [
    Category(
      id: 'c1',
      name: 'Corps',
      emoji: '💪',
      colorValue: 0xFFFF7043,
    ),
  ],
  habits: [
    Habit(
      id: 'h1',
      title: 'Pompes',
      categoryId: 'c1',
      difficulty: HabitDifficulty.normal, // 15 XP de base
      createdAt: today().subtract(const Duration(days: 30)),
    ),
  ],
);

/// Prépare un conteneur Riverpod adossé à un dépôt en mémoire.
({ProviderContainer container, AppController controller}) _setup([
  AppData? initial,
]) {
  final container = ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(
        InMemoryRepository(initial ?? _base()),
      ),
    ],
  );
  addTearDown(container.dispose);
  return (
    container: container,
    controller: container.read(appControllerProvider.notifier),
  );
}

Future<AppController> _ready(ProviderContainer container) async {
  await container.read(appControllerProvider.future);
  return container.read(appControllerProvider.notifier);
}

void main() {
  group('Barème d\'XP', () {
    final habit = _base().habits.first;

    test('sans série, on touche la valeur de base', () {
      expect(XpRules.awardFor(habit, streakBefore: 0), 15);
    });

    test('le bonus de série s\'ajoute par palier de deux', () {
      expect(XpRules.awardFor(habit, streakBefore: 1), 17);
      expect(XpRules.awardFor(habit, streakBefore: 5), 25);
    });

    test('le bonus est plafonné', () {
      expect(XpRules.awardFor(habit, streakBefore: 10), 35);
      expect(
        XpRules.awardFor(habit, streakBefore: 500),
        35,
        reason: 'une série interminable ne doit pas déséquilibrer le barème',
      );
    });
  });

  group('Pointage d\'une habitude', () {
    test('cocher crédite l\'XP à la catégorie', () async {
      final (:container, controller: _) = _setup();
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;

      final evenement = await controleur.cycleHabit(habit, today());

      expect(evenement, isNotNull);
      expect(evenement!.xpDelta, 15);
      expect(container.read(appDataProvider).categoryById('c1')!.xp, 15);
      expect(container.read(appDataProvider).totalXp, 15);
    });

    test('le cycle passe par réussi, manqué, puis rien', () async {
      final (:container, controller: _) = _setup();
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;
      final jour = today();

      await controleur.cycleHabit(habit, jour);
      expect(container.read(appDataProvider).logFor('h1', jour)!.done, isTrue);

      await controleur.cycleHabit(habit, jour);
      final manque = container.read(appDataProvider).logFor('h1', jour);
      expect(manque, isNotNull);
      expect(manque!.done, isFalse);

      await controleur.cycleHabit(habit, jour);
      expect(container.read(appDataProvider).logFor('h1', jour), isNull);
    });

    test('décocher reprend exactement l\'XP accordée', () async {
      final (:container, controller: _) = _setup();
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;
      final jour = today();

      await controleur.cycleHabit(habit, jour);
      final apresCoche = container.read(appDataProvider).categoryById('c1')!.xp;

      await controleur.cycleHabit(habit, jour); // passe en « manqué »
      expect(container.read(appDataProvider).categoryById('c1')!.xp, 0);
      expect(apresCoche, 15);
    });

    test(
      'l\'XP reprise correspond au bonus réellement accordé, pas au bonus actuel',
      () async {
        final (:container, controller: _) = _setup();
        final controleur = await _ready(container);
        final habit = container.read(appDataProvider).habits.first;

        // Trois jours d'affilée : les gains croissent avec la série.
        for (var i = 2; i >= 0; i--) {
          await controleur.cycleHabit(
            habit,
            today().subtract(Duration(days: i)),
          );
        }

        final data = container.read(appDataProvider);
        final total = data.categoryById('c1')!.xp;
        expect(total, 15 + 17 + 19);

        // On annule la toute première journée, dont le gain valait 15.
        await controleur.cycleHabit(
          habit,
          today().subtract(const Duration(days: 2)),
        );
        expect(
          container.read(appDataProvider).categoryById('c1')!.xp,
          total - 15,
          reason: 'chaque pointage mémorise le gain qu\'il a réellement produit',
        );
      },
    );

    test('l\'XP d\'une catégorie ne descend jamais sous zéro', () async {
      final (:container, controller: _) = _setup();
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;
      final jour = today();

      await controleur.cycleHabit(habit, jour);
      await controleur.cycleHabit(habit, jour);
      await controleur.cycleHabit(habit, jour);
      await controleur.cycleHabit(habit, jour); // recoche
      await controleur.cycleHabit(habit, jour); // décoche

      expect(container.read(appDataProvider).categoryById('c1')!.xp, 0);
    });

    test('un passage de niveau est signalé', () async {
      // 100 XP amènent au niveau 2 : on part à 90.
      final depart = _base();
      final (:container, controller: _) = _setup(
        depart.copyWith(
          categories: [depart.categories.first.copyWith(xp: 90)],
        ),
      );
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;

      final evenement = await controleur.cycleHabit(habit, today());

      expect(evenement!.leveledUp, isTrue);
      expect(evenement.newLevel, 2);
    });
  });

  group('Objectifs', () {
    test('cocher une étape crédite son XP, la décocher la reprend', () async {
      final depart = _base();
      final (:container, controller: _) = _setup(
        depart.copyWith(
          goals: [
            Goal(
              id: 'g1',
              title: 'Test',
              categoryId: 'c1',
              createdAt: today(),
              milestones: const [Milestone(id: 'm1', title: 'Étape')],
            ),
          ],
        ),
      );
      final controleur = await _ready(container);

      await controleur.toggleMilestone('g1', 'm1');
      expect(
        container.read(appDataProvider).categoryById('c1')!.xp,
        Milestone.xpReward,
      );
      expect(
        container.read(appDataProvider).goalById('g1')!.milestonesDone,
        1,
      );

      await controleur.toggleMilestone('g1', 'm1');
      expect(container.read(appDataProvider).categoryById('c1')!.xp, 0);
    });

    test('terminer un objectif verse sa prime', () async {
      final depart = _base();
      final (:container, controller: _) = _setup(
        depart.copyWith(
          goals: [
            Goal(
              id: 'g1',
              title: 'Test',
              categoryId: 'c1',
              createdAt: today(),
            ),
          ],
        ),
      );
      final controleur = await _ready(container);

      await controleur.toggleGoalCompletion('g1');
      final data = container.read(appDataProvider);
      expect(data.goalById('g1')!.isCompleted, isTrue);
      expect(data.categoryById('c1')!.xp, Goal.defaultXpReward);
      expect(data.goalById('g1')!.progress, 1);

      await controleur.toggleGoalCompletion('g1');
      expect(container.read(appDataProvider).categoryById('c1')!.xp, 0);
    });
  });

  group('Persistance', () {
    test('un export se relit à l\'identique', () async {
      final (:container, controller: _) = _setup();
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;
      await controleur.cycleHabit(habit, today());

      final json = controleur.exportJson();

      final autre = _setup(AppData());
      final autreControleur = await _ready(autre.container);
      await autreControleur.importJson(json);

      final restaure = autre.container.read(appDataProvider);
      expect(restaure.totalXp, 15);
      expect(restaure.habits.length, 1);
      expect(restaure.logFor('h1', today())!.done, isTrue);
    });

    test('supprimer une catégorie emporte son contenu et son XP', () async {
      final (:container, controller: _) = _setup();
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;
      await controleur.cycleHabit(habit, today());

      await controleur.deleteCategory('c1');

      final data = container.read(appDataProvider);
      expect(data.categories, isEmpty);
      expect(data.habits, isEmpty);
      expect(data.logs, isEmpty);
      expect(data.totalXp, 0);
    });
  });
}
