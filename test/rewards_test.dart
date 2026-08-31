import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/core/util/day.dart';
import 'package:levelia/data/json_file_repository.dart';
import 'package:levelia/domain/engine/leveling.dart';
import 'package:levelia/domain/engine/skill_tree.dart';
import 'package:levelia/domain/models/app_data.dart';
import 'package:levelia/domain/models/category.dart';
import 'package:levelia/domain/models/habit.dart';
import 'package:levelia/domain/models/reward.dart';
import 'package:levelia/state/app_controller.dart';
import 'package:levelia/state/providers.dart';

/// XP à déposer dans une catégorie pour l'amener au niveau [niveau].
int _xpPour(int niveau) => Leveling.cumulativeXpFor(niveau);

AppData _base({int xp = 0, List<Reward> rewards = const []}) => AppData(
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

/// Un conteneur dont les données sont déjà chargées.
///
/// Le contrôleur lit son dépôt de façon asynchrone : l'attendre évite de
/// tomber sur un état encore en chargement à la première mutation.
Future<({ProviderContainer container, AppController controller})> _setup(
  AppData initial,
) async {
  final container = ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(InMemoryRepository(initial)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appControllerProvider.future);
  return (
    container: container,
    controller: container.read(appControllerProvider.notifier),
  );
}

AppData _lire(ProviderContainer c) => c.read(appDataProvider);

Habit _habitude(ProviderContainer c) => _lire(c).habits.single;

void main() {
  group('Modèle de récompense', () {
    test('la branche globale se distingue par un domaine nul', () {
      const globale = Reward(id: 'r1', level: 5, title: 'Un jeu');
      const domaine = Reward(
        id: 'r2',
        level: 5,
        title: 'Des baskets',
        categoryId: 'c1',
      );
      expect(globale.isGlobal, isTrue);
      expect(domaine.isGlobal, isFalse);
    });

    test('elle se débloque au palier, pas avant', () {
      const r = Reward(id: 'r1', level: 5, title: 'Un jeu');
      expect(r.unlockedAt(4), isFalse);
      expect(r.unlockedAt(5), isTrue);
      expect(r.unlockedAt(9), isTrue);
    });

    test('elle survit à un aller-retour JSON', () {
      final r = Reward(
        id: 'r1',
        level: 7,
        title: 'Un week-end',
        categoryId: 'c1',
        claimedAt: DateTime(2026, 3, 4, 10, 30),
      );
      final relu = Reward.fromJson(r.toJson());
      expect(relu.id, r.id);
      expect(relu.level, r.level);
      expect(relu.title, r.title);
      expect(relu.categoryId, r.categoryId);
      expect(relu.claimedAt, r.claimedAt);
    });

    test('une sauvegarde antérieure se relit sans récompense', () {
      // Le champ est arrivé après coup : un fichier écrit par une version
      // précédente n'a pas la clé et ne doit pas faire échouer la lecture.
      final json = const AppData().toJson()..remove('rewards');
      expect(AppData.fromJson(json).rewards, isEmpty);
    });
  });

  group('Arbre de compétences', () {
    test('le tronc vient en tête, suivi des domaines actifs', () {
      final branches = SkillTree.branches(_base());
      expect(branches.first.isGlobal, isTrue);
      expect(branches.first.id, kGlobalBranchId);
      expect(branches.map((b) => b.name), ['Global', 'Corps']);
      expect(branches.first.rewardCategoryId, isNull);
      expect(branches.last.rewardCategoryId, 'c1');
    });

    test('les paliers commencent au niveau 2', () {
      // Le niveau 1 est le point de départ : il ne se franchit pas, donc il
      // n'a rien à porter.
      final corps = SkillTree.branches(_base()).last;
      expect(corps.nodes.first.level, 2);
    });

    test('l\'état des paliers suit le niveau atteint', () {
      final corps = SkillTree.branches(_base(xp: _xpPour(3))).last;
      final etats = {for (final n in corps.nodes) n.level: n.state};

      expect(corps.level, 3);
      expect(etats[2], NodeState.reached);
      expect(etats[3], NodeState.reached);
      expect(etats[4], NodeState.current);
      expect(etats[5], NodeState.locked);
    });

    test('une récompense lointaine reste visible', () {
      // Sans cela, une récompense posée loin disparaîtrait de l'arbre : on ne
      // peut pas viser ce qu'on ne voit pas.
      final corps = SkillTree.branches(
        _base(
          rewards: const [
            Reward(id: 'r1', level: 20, title: 'Un voyage', categoryId: 'c1'),
          ],
        ),
      ).last;
      expect(corps.nodes.last.level, greaterThanOrEqualTo(20));
      expect(corps.nodes.firstWhere((n) => n.level == 20).hasReward, isTrue);
    });

    test('un palier lointain ne fait pas exploser la branche', () {
      final corps = SkillTree.branches(
        _base(
          rewards: const [
            Reward(id: 'r1', level: 5000, title: 'Trop loin', categoryId: 'c1'),
          ],
        ),
      ).last;
      expect(corps.nodes.length, lessThanOrEqualTo(SkillTree.maxNodes));
    });

    test('une récompense atteinte et non prise se signale', () {
      final data = _base(
        xp: _xpPour(3),
        rewards: const [
          Reward(id: 'r1', level: 2, title: 'Un jeu', categoryId: 'c1'),
        ],
      );
      final corps = SkillTree.branches(data).last;

      expect(corps.waiting.map((n) => n.level), [2]);
      expect(data.rewardsWaiting.map((r) => r.id), ['r1']);
    });

    test('une récompense savourée ne réclame plus rien', () {
      final data = _base(
        xp: _xpPour(3),
        rewards: [
          Reward(
            id: 'r1',
            level: 2,
            title: 'Un jeu',
            categoryId: 'c1',
            claimedAt: DateTime(2026),
          ),
        ],
      );
      expect(data.rewardsWaiting, isEmpty);
      expect(SkillTree.branches(data).last.waiting, isEmpty);
    });
  });

  group('Gestion des récompenses', () {
    test('poser puis réécrire garde le même nœud', () async {
      final s = await _setup(_base());
      await s.controller.setReward(categoryId: 'c1', level: 4, title: 'Un jeu');
      final premiere = _lire(s.container).rewards.single;

      await s.controller.setReward(
        categoryId: 'c1',
        level: 4,
        title: 'Un jeu Steam',
      );
      final apres = _lire(s.container).rewards;

      // Un palier ne porte qu'une récompense, et corriger le texte ne doit pas
      // en créer une seconde.
      expect(apres, hasLength(1));
      expect(apres.single.id, premiere.id);
      expect(apres.single.title, 'Un jeu Steam');
    });

    test('tronc et domaine sont deux nœuds distincts', () async {
      final s = await _setup(_base());
      await s.controller.setReward(
        categoryId: null,
        level: 4,
        title: 'Globale',
      );
      await s.controller.setReward(categoryId: 'c1', level: 4, title: 'Corps');

      final data = _lire(s.container);
      expect(data.rewards, hasLength(2));
      expect(data.rewardsFor(null).single.title, 'Globale');
      expect(data.rewardsFor('c1').single.title, 'Corps');
    });

    test('un texte vide ou un palier absurde est refusé', () async {
      final s = await _setup(_base());
      await s.controller.setReward(categoryId: 'c1', level: 4, title: '   ');
      await s.controller.setReward(categoryId: 'c1', level: 1, title: 'Niv 1');
      expect(_lire(s.container).rewards, isEmpty);
    });

    test('on ne savoure pas une récompense non méritée', () async {
      final s = await _setup(
        _base(
          rewards: const [
            Reward(id: 'r1', level: 9, title: 'Un jeu', categoryId: 'c1'),
          ],
        ),
      );
      await s.controller.toggleRewardClaimed('r1');
      expect(_lire(s.container).rewards.single.claimed, isFalse);
    });

    test('une fois le palier atteint, elle se coche et se décoche', () async {
      final s = await _setup(
        _base(
          xp: _xpPour(4),
          rewards: const [
            Reward(id: 'r1', level: 3, title: 'Un jeu', categoryId: 'c1'),
          ],
        ),
      );
      await s.controller.toggleRewardClaimed('r1');
      expect(_lire(s.container).rewards.single.claimed, isTrue);

      await s.controller.toggleRewardClaimed('r1');
      expect(_lire(s.container).rewards.single.claimed, isFalse);
    });

    test('retirer une récompense laisse les autres en place', () async {
      final s = await _setup(
        _base(
          rewards: const [
            Reward(id: 'r1', level: 3, title: 'A', categoryId: 'c1'),
            Reward(id: 'r2', level: 4, title: 'B', categoryId: 'c1'),
          ],
        ),
      );
      await s.controller.removeReward('r1');
      expect(_lire(s.container).rewards.map((r) => r.id), ['r2']);
    });
  });

  group('Passage de niveau', () {
    test('un pointage qui fait monter signale les deux branches', () async {
      // 85 XP dans l'unique catégorie : les 15 XP du pointage franchissent les
      // 100 XP du niveau 2, sur la catégorie comme sur le tronc, puisque le
      // total global n'est fait que de cette catégorie.
      final s = await _setup(_base(xp: 85));
      final event = await s.controller.setHabitDone(
        _habitude(s.container),
        today(),
        done: true,
      );

      expect(event, isNotNull);
      expect(event!.leveledUp, isTrue);
      expect(event.previousLevel, 1);
      expect(event.newLevel, 2);
      expect(event.globalLeveledUp, isTrue);
      expect(event.previousGlobalLevel, 1);
      expect(event.globalLevel, 2);
      expect(event.anyLevelUp, isTrue);
    });

    test('les récompenses franchies remontent avec l\'événement', () async {
      final s = await _setup(
        _base(
          xp: 85,
          rewards: const [
            Reward(id: 'r1', level: 2, title: 'Un jeu', categoryId: 'c1'),
            Reward(id: 'r2', level: 2, title: 'Un resto'),
            Reward(id: 'r3', level: 3, title: 'Trop tôt', categoryId: 'c1'),
          ],
        ),
      );
      final event = await s.controller.setHabitDone(
        _habitude(s.container),
        today(),
        done: true,
      );

      // Le palier 2 des deux branches tombe ; le palier 3 attend son tour.
      expect(event!.unlocked.map((r) => r.id), unorderedEquals(['r1', 'r2']));
    });

    test('un pointage sans montée ne débloque rien', () async {
      final s = await _setup(
        _base(
          rewards: const [
            Reward(id: 'r1', level: 2, title: 'Un jeu', categoryId: 'c1'),
          ],
        ),
      );
      final event = await s.controller.setHabitDone(
        _habitude(s.container),
        today(),
        done: true,
      );

      expect(event!.anyLevelUp, isFalse);
      expect(event.unlocked, isEmpty);
    });

    test('reprendre de l\'XP ne redonne aucune récompense', () async {
      // Décocher fait redescendre : les bornes sont ouvertes à gauche, donc
      // rien ne doit se rejouer au passage.
      final s = await _setup(
        _base(
          xp: 85,
          rewards: const [
            Reward(id: 'r1', level: 2, title: 'Un jeu', categoryId: 'c1'),
          ],
        ),
      );
      await s.controller.setHabitDone(
        _habitude(s.container),
        today(),
        done: true,
      );
      final retour = await s.controller.setHabitDone(
        _habitude(s.container),
        today(),
        done: false,
      );

      expect(retour!.unlocked, isEmpty);
      expect(retour.anyLevelUp, isFalse);
    });
  });
}
