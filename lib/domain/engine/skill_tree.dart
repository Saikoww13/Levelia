import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import '../models/app_data.dart';
import '../models/reward.dart';
import 'leveling.dart';

/// Identifiant de la branche du tronc, celle du niveau global.
///
/// `null` porte déjà ce sens dans [Reward.categoryId] ; cette constante sert
/// aux endroits où il faut une clé, comme une sélection d'interface.
const String kGlobalBranchId = '_global';

/// État d'un nœud de l'arbre, du point de vue de la progression.
enum NodeState {
  /// Niveau déjà franchi.
  reached,

  /// Le prochain niveau à atteindre sur cette branche.
  current,

  /// Encore hors de portée.
  locked,
}

/// Un palier de l'arbre : un niveau sur une branche, avec sa récompense
/// éventuelle.
@immutable
class SkillNode {
  const SkillNode({
    required this.level,
    required this.state,
    required this.reward,
    required this.progress,
  });

  final int level;
  final NodeState state;

  /// Récompense posée sur ce palier, s'il y en a une.
  final Reward? reward;

  /// Avancement vers ce palier, entre 0 et 1. Ne vaut autre chose que 0 ou 1
  /// que pour le nœud [NodeState.current].
  final double progress;

  bool get hasReward => reward != null;

  /// Vrai si une récompense est débloquée mais pas encore savourée.
  bool get rewardWaiting =>
      reward != null && state == NodeState.reached && !reward!.claimed;
}

/// Une branche de l'arbre : le tronc global, ou un domaine.
@immutable
class SkillBranch {
  const SkillBranch({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.info,
    required this.nodes,
    required this.isGlobal,
  });

  /// [kGlobalBranchId] pour le tronc, sinon l'identifiant du domaine.
  final String id;
  final String name;
  final String emoji;
  final int colorValue;

  /// Progression de la branche.
  final LevelInfo info;

  /// Paliers, du niveau 2 vers le haut.
  final List<SkillNode> nodes;

  final bool isGlobal;

  /// Identifiant de domaine à stocker dans une [Reward] posée sur cette
  /// branche : `null` pour le tronc.
  String? get rewardCategoryId => isGlobal ? null : id;

  int get level => info.level;

  /// Récompenses débloquées et pas encore savourées sur cette branche.
  Iterable<SkillNode> get waiting => nodes.where((n) => n.rewardWaiting);
}

/// Construit la vue « arbre de compétences » à partir des données.
class SkillTree {
  const SkillTree._();

  /// Nombre de paliers montrés au-delà du niveau courant.
  ///
  /// Assez pour donner un horizon où poser une récompense, assez peu pour que
  /// la branche ne parte pas en liste interminable.
  static const int lookahead = 3;

  /// Garde-fou : une récompense posée très haut ne doit pas faire dessiner des
  /// centaines de nœuds.
  static const int maxNodes = 60;

  /// Dernier palier à dessiner sur une branche.
  ///
  /// On montre toujours au moins jusqu'à la récompense la plus lointaine :
  /// une récompense que l'on ne verrait pas ne motiverait personne.
  static int horizon(int level, Iterable<Reward> rewards) {
    final plusHaute = rewards.fold<int>(0, (m, r) => math.max(m, r.level));
    final vise = math.max(level + lookahead, math.max(plusHaute, 5));
    return math.min(vise, level + maxNodes);
  }

  /// Les branches de l'arbre : le tronc global d'abord, puis les domaines
  /// actifs dans leur ordre d'affichage habituel.
  static List<SkillBranch> branches(AppData data) {
    final global = _branche(
      id: kGlobalBranchId,
      name: 'Global',
      emoji: '⚔️',
      colorValue: 0xFF3A8FD1,
      info: data.globalLevel,
      rewards: data.rewardsFor(null),
      isGlobal: true,
    );

    return [
      global,
      for (final c in data.activeCategories)
        _branche(
          id: c.id,
          name: c.name,
          emoji: c.emoji,
          colorValue: c.colorValue,
          info: c.levelInfo,
          rewards: data.rewardsFor(c.id),
          isGlobal: false,
        ),
    ];
  }

  static SkillBranch _branche({
    required String id,
    required String name,
    required String emoji,
    required int colorValue,
    required LevelInfo info,
    required List<Reward> rewards,
    required bool isGlobal,
  }) {
    final parNiveau = <int, Reward>{for (final r in rewards) r.level: r};
    final fin = horizon(info.level, rewards);

    return SkillBranch(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      info: info,
      isGlobal: isGlobal,
      // Le palier 1 n'existe pas : on démarre au niveau 1, on ne le franchit
      // pas. Le premier nœud dessiné est donc le niveau 2.
      nodes: [
        for (var n = 2; n <= fin; n++)
          SkillNode(
            level: n,
            state: n <= info.level
                ? NodeState.reached
                : n == info.level + 1
                ? NodeState.current
                : NodeState.locked,
            reward: parNiveau[n],
            progress: n <= info.level
                ? 1
                : n == info.level + 1
                ? info.progress
                : 0,
          ),
      ],
    );
  }
}
