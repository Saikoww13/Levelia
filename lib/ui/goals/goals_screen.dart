import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/category.dart';
import '../../domain/models/goal.dart';
import '../../state/providers.dart';
import '../widgets/category_widgets.dart';
import '../widgets/common.dart';
import '../widgets/xp_feedback.dart';
import 'goal_editor.dart';

/// Les objectifs : des destinations à moyen terme, découpées en étapes.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);

    final ouverts = data.openGoals
      ..sort((a, b) {
        // Les échéances les plus proches remontent ; les objectifs sans date
        // se rangent après.
        final da = a.targetDate;
        final db = b.targetDate;
        if (da == null && db == null) return a.title.compareTo(b.title);
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    final termines = data.completedGoals;

    return AppPage(
      title: 'Objectifs',
      trailing: NavAddButton(
        onPressed: () => openGoalEditor(context, ref),
        semantic: 'Nouvel objectif',
      ),
      children: [
        if (ouverts.isEmpty && termines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: EmptyState(
              icon: CupertinoIcons.flag,
              title: 'Aucun objectif',
              message:
                  'Un objectif donne une direction à tes habitudes. Découpe-le en étapes : chacune rapporte ${Milestone.xpReward} XP.',
              action: CupertinoButton.filled(
                onPressed: () => openGoalEditor(context, ref),
                child: const Text('Créer un objectif'),
              ),
            ),
          )
        else ...[
          if (ouverts.isNotEmpty) ...[
            const SectionTitle(title: 'En cours'),
            for (final objectif in ouverts) ...[
              _GoalCard(
                goal: objectif,
                category: data.categoryById(objectif.categoryId),
              ),
              Gaps.h12,
            ],
          ],
          if (termines.isNotEmpty) ...[
            Gaps.h16,
            SectionTitle(title: 'Atteints (${termines.length})'),
            for (final objectif in termines) ...[
              _GoalCard(
                goal: objectif,
                category: data.categoryById(objectif.categoryId),
              ),
              Gaps.h12,
            ],
          ],
        ],
      ],
    );
  }
}

/// Carte d'objectif dépliable : l'entête montre l'avancement, le corps les étapes.
class _GoalCard extends ConsumerStatefulWidget {
  const _GoalCard({required this.goal, required this.category});

  final Goal goal;
  final Category? category;

  @override
  ConsumerState<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<_GoalCard> {
  bool _deplie = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final objectif = widget.goal;
    final couleur = widget.category?.color ?? AppTheme.seed;
    final controleur = ref.read(appControllerProvider.notifier);

    final label = c.label;
    final secondaire = c.secondary;

    return AppCard(
      accent: couleur,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _deplie = !_deplie),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.category != null) ...[
                  CategoryAvatar(category: widget.category!, size: 36),
                  Gaps.w12,
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        objectif.title,
                        style: AppText.title(label, size: 15).copyWith(
                          decoration: objectif.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Gaps.h8,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 6,
                          child: Stack(
                            children: [
                              Container(color: couleur.withValues(alpha: 0.14)),
                              FractionallySizedBox(
                                widthFactor: objectif.progress.clamp(0.0, 1.0),
                                child: Container(
                                  color: objectif.isCompleted
                                      ? AppTheme.success
                                      : couleur,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Gaps.h8,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (objectif.milestones.isNotEmpty)
                            Flexible(
                              child: Text(
                                '${objectif.milestonesDone}/${objectif.milestones.length} étapes',
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption(secondaire, size: 12),
                              ),
                            ),
                          Gaps.w8,
                          Flexible(child: _DeadlineLabel(goal: objectif)),
                        ],
                      ),
                    ],
                  ),
                ),
                Gaps.w8,
                Icon(
                  _deplie
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 15,
                  color: secondaire,
                ),
              ],
            ),
          ),
          if (_deplie) ...[
            Gaps.h12,
            Container(height: 0.5, color: c.separator),
            Gaps.h12,
            if (objectif.description.isNotEmpty) ...[
              Text(
                objectif.description,
                style: AppText.caption(secondaire, size: 13),
              ),
              Gaps.h12,
            ],
            for (final etape in objectif.milestones)
              _MilestoneRow(
                milestone: etape,
                color: couleur,
                onToggle: () async {
                  final evenement = await controleur.toggleMilestone(
                    objectif.id,
                    etape.id,
                  );
                  if (!context.mounted) return;
                  showXpFeedback(context, ref.read(appDataProvider), evenement);
                },
              ),
            Gaps.h8,
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  onPressed: () => openGoalEditor(context, ref, goal: objectif),
                  child: const Text('Modifier', style: TextStyle(fontSize: 14)),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 34),
                  borderRadius: BorderRadius.circular(17),
                  color: objectif.isCompleted ? c.field : AppTheme.success,
                  onPressed: () async {
                    final evenement = await controleur.toggleGoalCompletion(
                      objectif.id,
                    );
                    if (!context.mounted) return;
                    showXpFeedback(
                      context,
                      ref.read(appDataProvider),
                      evenement,
                    );
                  },
                  child: Text(
                    objectif.isCompleted
                        ? 'Rouvrir'
                        : 'Atteint · +${objectif.xpReward} XP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: objectif.isCompleted
                          ? secondaire
                          : CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne d'étape avec sa case ronde, au format iOS.
class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.color,
    required this.onToggle,
  });

  final Milestone milestone;
  final Color color;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = c.label;
    final secondaire = c.secondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(
              milestone.done
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 21,
              color: milestone.done ? AppTheme.success : secondaire,
            ),
            Gaps.w12,
            Expanded(
              child: Text(
                milestone.title,
                style:
                    AppText.body(
                      milestone.done ? secondaire : label,
                      size: 14,
                    ).copyWith(
                      decoration: milestone.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
              ),
            ),
            Text(
              '+${Milestone.xpReward}',
              style: AppText.readout(
                size: 13,
                color: secondaire,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Échéance affichée en clair : « Dans 5 jours », « En retard de 3 j ».
class _DeadlineLabel extends StatelessWidget {
  const _DeadlineLabel({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final secondaire = c.secondary;

    if (goal.isCompleted) {
      return Text(
        'Atteint',
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption(
          AppTheme.success,
          size: 12,
        ).copyWith(fontWeight: FontWeight.w600),
      );
    }

    final restants = goal.daysLeft;
    if (restants == null) {
      return Text(
        'Sans échéance',
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption(secondaire, size: 12),
      );
    }

    final (texte, couleur) = switch (restants) {
      < 0 => ('En retard de ${-restants} j', AppTheme.missed),
      0 => ('C\'est aujourd\'hui', AppTheme.streak),
      1 => ('Demain', AppTheme.streak),
      < 8 => ('Dans $restants jours', AppTheme.streak),
      _ => ('Le ${shortDayLabel(goal.targetDate!)}', secondaire),
    };

    return Text(
      texte,
      textAlign: TextAlign.end,
      overflow: TextOverflow.ellipsis,
      style: AppText.caption(
        couleur,
        size: 12,
      ).copyWith(fontWeight: FontWeight.w600),
    );
  }
}
