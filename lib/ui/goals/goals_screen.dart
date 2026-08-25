import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/category.dart';
import '../../domain/models/goal.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openGoalEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Objectif'),
      ),
      body: ouverts.isEmpty && termines.isEmpty
          ? EmptyState(
              icon: Icons.flag_outlined,
              title: 'Aucun objectif',
              message:
                  'Un objectif donne une direction à tes habitudes. Découpe-le en étapes : chacune rapporte ${Milestone.xpReward} XP.',
              action: FilledButton.icon(
                onPressed: () => openGoalEditor(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Créer un objectif'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
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
            ),
    );
  }
}

/// Carte d'objectif dépliable : l'entête montre l'avancement, le contenu les étapes.
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.category});

  final Goal goal;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final couleur = category?.color ?? theme.colorScheme.primary;
    final controleur = ref.read(appControllerProvider.notifier);

    return AppCard(
      accent: couleur,
      padding: EdgeInsets.zero,
      child: Theme(
        // On retire les séparateurs par défaut de l'ExpansionTile, la carte
        // fournit déjà son propre cadre.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: category == null
              ? null
              : CategoryAvatar(category: category!, size: 38),
          title: Text(
            goal.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 6,
                    backgroundColor: couleur.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      goal.isCompleted ? AppTheme.success : couleur,
                    ),
                  ),
                ),
                Gaps.h8,
                // Les deux libellés sont bornés : sur un écran étroit, une
                // échéance longue ne doit pas pousser le compteur hors du cadre.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (goal.milestones.isNotEmpty)
                      Flexible(
                        child: Text(
                          '${goal.milestonesDone}/${goal.milestones.length} étapes',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Gaps.w8,
                    Flexible(child: _DeadlineLabel(goal: goal)),
                  ],
                ),
              ],
            ),
          ),
          children: [
            if (goal.description.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  goal.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Gaps.h12,
            ],
            for (final etape in goal.milestones)
              CheckboxListTile(
                value: etape.done,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  etape.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: etape.done ? TextDecoration.lineThrough : null,
                    color: etape.done
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                secondary: Text(
                  '+${Milestone.xpReward} XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (_) async {
                  final evenement = await controleur.toggleMilestone(
                    goal.id,
                    etape.id,
                  );
                  if (!context.mounted) return;
                  showXpFeedback(context, ref.read(appDataProvider), evenement);
                },
              ),
            Gaps.h8,
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => openGoalEditor(context, ref, goal: goal),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier'),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final evenement = await controleur.toggleGoalCompletion(
                      goal.id,
                    );
                    if (!context.mounted) return;
                    showXpFeedback(
                      context,
                      ref.read(appDataProvider),
                      evenement,
                    );
                  },
                  icon: Icon(
                    goal.isCompleted ? Icons.undo : Icons.emoji_events,
                    size: 18,
                  ),
                  label: Text(
                    goal.isCompleted
                        ? 'Rouvrir'
                        : 'Atteint (+${goal.xpReward} XP)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Échéance affichée en clair : « dans 12 jours », « en retard de 3 jours ».
class _DeadlineLabel extends StatelessWidget {
  const _DeadlineLabel({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (goal.isCompleted) {
      return Text(
        'Atteint 🏆',
        textAlign: TextAlign.end,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppTheme.success,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final restants = goal.daysLeft;
    if (restants == null) {
      return Text(
        'Sans échéance',
        textAlign: TextAlign.end,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final (texte, couleur) = switch (restants) {
      < 0 => ('En retard de ${-restants} j', theme.colorScheme.error),
      0 => ('C\'est aujourd\'hui', AppTheme.streak),
      1 => ('Demain', AppTheme.streak),
      < 8 => ('Dans $restants jours', AppTheme.streak),
      _ => (
        'Le ${shortDayLabel(goal.targetDate!)}',
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Text(
      texte,
      textAlign: TextAlign.end,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: couleur,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
