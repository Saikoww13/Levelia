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

  group('Pénalité XP', () {
    // Habitude facile (10 XP) + pénalité sévère (25 XP) sur catégorie vierge.
    // C'est exactement la configuration qui produisait le bug : la pénalité
    // nominale (25) dépassait l'XP disponible (10), le clamp absorbait la
    // différence, mais _markMissed enregistrait quand même 25. À l'effacement,
    // _clearLog restituait 25 alors que seul 0 avait été prélevé.
    AppData baseAvecPenalite() {
      final b = _base();
      return b.copyWith(
        habits: [
          b.habits.first.copyWith(
            difficulty: HabitDifficulty.easy,   // 10 XP
            penalty: HabitPenalty.severe,        // 25 XP
          ),
        ],
      );
    }

    test(
      'pénalité nulle quand le clamp absorbe tout : marquer manqué puis effacer '
      'ne crée pas d\'XP',
      () async {
        // Catégorie à 0 XP. Gain = 10, pénalité nominale = 25.
        // Après « manqué » : (0 + 10 - 10 - 25).clamp(0) = 0.
        // Pénalité réellement prélevée = 0, donc effacer doit rendre 0.
        final (:container, controller: _) = _setup(baseAvecPenalite());
        final controleur = await _ready(container);
        final habit = container.read(appDataProvider).habits.first;
        final jour = today();

        await controleur.cycleHabit(habit, jour); // réussi  → XP = 10
        await controleur.cycleHabit(habit, jour); // manqué  → XP = 0 (clampé)
        await controleur.cycleHabit(habit, jour); // effacé  → XP doit rester 0

        expect(
          container.read(appDataProvider).categoryById('c1')!.xp,
          0,
          reason: 'effacer un pointage manqué ne doit jamais créer d\'XP',
        );
      },
    );

    test('pénalité partielle quand l\'XP disponible est insuffisante', () async {
      // Catégorie à 5 XP avant le pointage. Gain = 10 → XP = 15.
      // delta = -10 - 25 = -35 → (15 - 35).clamp(0) = 0.
      // Pénalité réelle = 0 - 15 - (-10) = 5 (les 5 XP hors du gain).
      final base = baseAvecPenalite();
      final (:container, controller: _) = _setup(
        base.copyWith(
          categories: [base.categories.first.copyWith(xp: 5)],
        ),
      );
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;
      final jour = today();

      await controleur.cycleHabit(habit, jour); // réussi  → XP = 15
      await controleur.cycleHabit(habit, jour); // manqué  → XP = 0
      await controleur.cycleHabit(habit, jour); // effacé  → XP doit revenir à 5

      expect(
        container.read(appDataProvider).categoryById('c1')!.xp,
        5,
        reason: 'effacer restitue la pénalité réelle, pas la pénalité nominale',
      );
    });

    test(
      'régression : pénalité sévère sur catégorie vierge ne crée pas d\'XP',
      () async {
        // Reproduit exactement le bug signalé :
        // catégorie neuve (0 XP), habitude facile (10 XP), pénalité sévère (25 XP).
        // Avant le correctif, _markMissed stockait xpPenaltyApplied = 25 même si
        // le clamp n'avait retiré que 0. _clearLog restituait 25 → XP créée de rien.
        final (:container, controller: _) = _setup(baseAvecPenalite());
        final controleur = await _ready(container);
        final habit = container.read(appDataProvider).habits.first;
        final jour = today();

        // Étape 1 — marquer réussi : la catégorie gagne 10 XP.
        await controleur.cycleHabit(habit, jour);
        expect(container.read(appDataProvider).categoryById('c1')!.xp, 10);

        // Étape 2 — marquer manqué : delta = -10 - 25 = -35, clampé à 0.
        // La pénalité réellement prélevée est 0, pas 25.
        await controleur.cycleHabit(habit, jour);
        expect(container.read(appDataProvider).categoryById('c1')!.xp, 0);

        final logManque = container.read(appDataProvider).logFor('h1', jour);
        expect(
          logManque?.xpPenaltyApplied,
          0,
          reason: 'xpPenaltyApplied doit refléter ce qui a été réellement prélevé, '
              'pas la valeur nominale de la pénalité',
        );

        // Étape 3 — effacer : restitue xpPenaltyApplied = 0 → XP reste à 0.
        await controleur.cycleHabit(habit, jour);
        expect(
          container.read(appDataProvider).categoryById('c1')!.xp,
          0,
          reason: 'effacer un pointage manqué ne doit jamais créer d\'XP',
        );
      },
    );

    test('pénalité pleine quand l\'XP disponible est suffisante', () async {
      // Catégorie à 100 XP avant le pointage. Gain = 10 → XP = 110.
      // delta = -35 → XP = 75, aucun clamp.
      // Pénalité réelle = 25 (nominale entière).
      // Effacer : XP revient à 100.
      final base = baseAvecPenalite();
      final (:container, controller: _) = _setup(
        base.copyWith(
          categories: [base.categories.first.copyWith(xp: 100)],
        ),
      );
      final controleur = await _ready(container);
      final habit = container.read(appDataProvider).habits.first;
      final jour = today();

      await controleur.cycleHabit(habit, jour); // réussi  → XP = 110
      await controleur.cycleHabit(habit, jour); // manqué  → XP = 75
      await controleur.cycleHabit(habit, jour); // effacé  → XP doit revenir à 100

      expect(
        container.read(appDataProvider).categoryById('c1')!.xp,
        100,
      );
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
