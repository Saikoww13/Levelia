import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/skill_tree.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/modal_page.dart';
import 'branch_path.dart';

/// L'arbre de compétences : une branche par domaine, plus le tronc global.
///
/// C'est la vue de long terme de l'application. « Progression » dit où l'on en
/// est cette semaine ; l'arbre dit où l'on va, et ce qu'on s'est promis en
/// chemin.
class TreeScreen extends ConsumerWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final data = ref.watch(appDataProvider);
    final branches = SkillTree.branches(data);
    final enAttente = data.rewardsWaiting;

    return AppPage(
      title: 'Arbre',
      children: [
        if (enAttente.isNotEmpty) ...[
          _Moisson(count: enAttente.length),
          Gaps.h16,
        ],
        if (data.activeCategories.isEmpty)
          const EmptyState(
            icon: CupertinoIcons.sparkles,
            title: 'Aucun domaine',
            message:
                'Crée un domaine depuis le Profil : chacun fera pousser sa '
                'propre branche.',
          ),
        for (final branche in branches) ...[
          _BranchCard(branch: branche),
          Gaps.h16,
        ],
        if (branches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Touche un palier pour y accrocher une récompense : ce que tu '
              't\'accordes en l\'atteignant.',
              style: AppText.caption(c.tertiary),
            ),
          ),
      ],
    );
  }
}

/// Rappel des récompenses débloquées qui attendent encore.
class _Moisson extends StatelessWidget {
  const _Moisson({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final pluriel = count > 1;
    return AppCard(
      accent: AppTheme.streak,
      child: Row(
        children: [
          Icon(CupertinoIcons.rosette, color: AppTheme.streak, size: 22),
          Gaps.w12,
          Expanded(
            child: Text(
              pluriel
                  ? '$count récompenses t\'attendent'
                  : 'Une récompense t\'attend',
              style: AppText.body(
                AppColors.of(context).label,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une branche : son en-tête et son chemin de paliers.
class _BranchCard extends ConsumerWidget {
  const _BranchCard({required this.branch});

  final SkillBranch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final couleur = Color(branch.colorValue);

    return AppCard(
      accent: couleur,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(branch.emoji, style: AppText.emoji(20)),
              Gaps.w8,
              Expanded(
                child: Text(
                  branch.name,
                  style: AppText.title(c.label, size: 17),
                ),
              ),
              Text(
                'NIV ${branch.level}',
                style: AppText.readout(size: 15, color: couleur),
              ),
            ],
          ),
          Gaps.h4,
          Text(
            branch.info.xpForNextLevel == 0
                ? branch.info.rank
                : '${branch.info.rank} · ${branch.info.xpRemaining} XP avant '
                      'le niveau ${branch.level + 1}',
            style: AppText.caption(c.secondary),
          ),
          Gaps.h12,
          BranchPath(
            branch: branch,
            onTapNode: (node) => _ouvrirNoeud(context, ref, branch, node),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirNoeud(
    BuildContext context,
    WidgetRef ref,
    SkillBranch branche,
    SkillNode node,
  ) async {
    final controleur = ref.read(appControllerProvider.notifier);
    final recompense = node.reward;

    // Pas de récompense : on va droit à la saisie, l'intention est sans
    // ambiguïté. Sinon on présente les actions possibles.
    if (recompense == null) {
      await _saisir(context, ref, branche, node);
      return;
    }

    if (!context.mounted) return;
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (contexte) => CupertinoActionSheet(
        title: Text('Niveau ${node.level} · ${branche.name}'),
        message: Text(recompense.title),
        actions: [
          if (node.state == NodeState.reached)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(contexte).pop('savourer'),
              child: Text(
                recompense.claimed
                    ? 'Remettre en attente'
                    : 'Marquer comme savourée',
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(contexte).pop('modifier'),
            child: const Text('Modifier'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(contexte).pop('retirer'),
            child: const Text('Retirer la récompense'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(contexte).pop(),
          child: const Text('Annuler'),
        ),
      ),
    );

    switch (action) {
      case 'savourer':
        await controleur.toggleRewardClaimed(recompense.id);
      case 'modifier':
        if (context.mounted) await _saisir(context, ref, branche, node);
      case 'retirer':
        await controleur.removeReward(recompense.id);
    }
  }

  Future<void> _saisir(
    BuildContext context,
    WidgetRef ref,
    SkillBranch branche,
    SkillNode node,
  ) async {
    final texte = await showAppModal<String>(
      context: context,
      builder: (contexte) => _RewardForm(
        branchName: branche.name,
        level: node.level,
        initial: node.reward?.title ?? '',
      ),
    );
    if (texte == null) return;

    await ref
        .read(appControllerProvider.notifier)
        .setReward(
          categoryId: branche.rewardCategoryId,
          level: node.level,
          title: texte,
        );
  }
}

/// Saisie du texte d'une récompense.
class _RewardForm extends StatefulWidget {
  const _RewardForm({
    required this.branchName,
    required this.level,
    required this.initial,
  });

  final String branchName;
  final int level;
  final String initial;

  @override
  State<_RewardForm> createState() => _RewardFormState();
}

class _RewardFormState extends State<_RewardForm> {
  late final TextEditingController _champ = TextEditingController(
    text: widget.initial,
  );

  @override
  void initState() {
    super.initState();
    _champ.addListener(_rafraichir);
  }

  void _rafraichir() => setState(() {});

  @override
  void dispose() {
    _champ.removeListener(_rafraichir);
    _champ.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final valide = _champ.text.trim().isNotEmpty;

    return AppFormPage(
      title: 'Niveau ${widget.level}',
      actionLabel: 'Enregistrer',
      onAction: valide
          ? () => Navigator.of(context).pop(_champ.text.trim())
          : null,
      children: [
        const FormLabel('Ta récompense'),
        AppTextField(
          controller: _champ,
          placeholder: 'M\'offrir ce jeu sur Steam',
          autofocus: true,
          maxLines: 3,
        ),
        Gaps.h12,
        Text(
          'Elle se débloquera en atteignant le niveau ${widget.level} de '
          '« ${widget.branchName} ». À toi de tenir parole.',
          style: AppText.caption(c.secondary),
        ),
      ],
    );
  }
}
