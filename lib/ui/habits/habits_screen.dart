import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/streaks.dart';
import '../../domain/models/category.dart';
import '../../domain/models/habit.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import 'habit_editor.dart';

/// Toutes les habitudes, rangées par catégorie, avec leur régularité.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final actives = data.activeHabits;
    final archivees = data.habits.where((h) => h.archived).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Habitudes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openHabitEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Habitude'),
      ),
      body: actives.isEmpty && archivees.isEmpty
          ? EmptyState(
              icon: Icons.checklist_rtl,
              title: 'Aucune habitude',
              message:
                  'Les habitudes sont le moteur de ta progression : chaque journée tenue rapporte de l\'XP à sa catégorie.',
              action: FilledButton.icon(
                onPressed: () => openHabitEditor(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Créer une habitude'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final categorie in data.activeCategories)
                  if (data.habitsOf(categorie.id).isNotEmpty)
                    _CategorySection(
                      category: categorie,
                      habits: data.habitsOf(categorie.id),
                    ),
                if (archivees.isNotEmpty) ...[
                  Gaps.h16,
                  const SectionTitle(title: 'Archivées'),
                  for (final habitude in archivees)
                    _ArchivedTile(habit: habitude),
                ],
              ],
            ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.category, required this.habits});

  final Category category;
  final List<Habit> habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(category: category, size: 30),
              Gaps.w8,
              Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gaps.w8,
              Text(
                'Niv. ${category.levelInfo.level}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: category.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Gaps.h12,
          for (final habitude in habits) ...[
            _HabitRow(habit: habitude, category: category),
            Gaps.h8,
          ],
        ],
      ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.habit, required this.category});

  final Habit habit;
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final serie = Streaks.of(data, habit);
    final theme = Theme.of(context);
    final taux = (serie.completionRate * 100).round();

    return AppCard(
      accent: category.color,
      onTap: () => openHabitEditor(context, ref, habit: habit),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (habit.isNegative) ...[
                      Icon(
                        Icons.block,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Gaps.w4,
                    ],
                    Expanded(
                      child: Text(
                        habit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.h4,
                Text(
                  habit.penalty == HabitPenalty.none
                      ? '${habit.schedule.label} · ${habit.difficulty.label}'
                      : '${habit.schedule.label} · ${habit.difficulty.label} · '
                            '-${habit.penalty.xp} XP si manquée',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Gaps.h8,
                // Wrap plutôt que Row : sur un écran étroit, le libellé de
                // série et le taux ne tiennent pas toujours sur une ligne.
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StreakPill(
                      label: serie.current > 0
                          ? serie.currentLabel
                          : 'Série à lancer',
                      active: serie.current > 0,
                    ),
                    Text(
                      '$taux % de réussite',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Actions',
            onSelected: (action) async {
              final controleur = ref.read(appControllerProvider.notifier);
              switch (action) {
                case 'edit':
                  await openHabitEditor(context, ref, habit: habit);
                case 'archive':
                  await controleur.archiveHabit(habit.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'archive', child: Text('Archiver')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchivedTile extends ConsumerWidget {
  const _ArchivedTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                habit.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .archiveHabit(habit.id, archived: false),
              child: const Text('Réactiver'),
            ),
          ],
        ),
      ),
    );
  }
}
