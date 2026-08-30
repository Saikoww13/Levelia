import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/streaks.dart';
import '../../domain/models/category.dart';
import '../../domain/models/habit.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import 'habit_editor.dart';

/// Toutes les habitudes, rangées par domaine, avec leur régularité.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final actives = data.activeHabits;
    final archivees = data.habits.where((h) => h.archived).toList();

    return AppPage(
      title: 'Habitudes',
      trailing: NavAddButton(
        onPressed: () => openHabitEditor(context, ref),
        semantic: 'Nouvelle habitude',
      ),
      children: [
        if (actives.isEmpty && archivees.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: EmptyState(
              icon: CupertinoIcons.checkmark_circle,
              title: 'Aucune habitude',
              message:
                  'Les habitudes sont le moteur de ta progression : chaque journée tenue rapporte de l\'XP à son domaine.',
              action: CupertinoButton.filled(
                onPressed: () => openHabitEditor(context, ref),
                child: const Text('Créer une habitude'),
              ),
            ),
          )
        else ...[
          for (final categorie in data.activeCategories)
            if (data.habitsOf(categorie.id).isNotEmpty)
              _CategorySection(
                category: categorie,
                habits: data.habitsOf(categorie.id),
              ),
          if (archivees.isNotEmpty) ...[
            Gaps.h16,
            const SectionTitle(title: 'Archivées'),
            for (final habitude in archivees) _ArchivedTile(habit: habitude),
          ],
        ],
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.habits});

  final Category category;
  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoDynamicColor.resolve(AppTheme.label, context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(category: category, size: 28),
              Gaps.w8,
              Text(category.name, style: AppText.title(label, size: 17)),
              Gaps.w8,
              Text(
                'NIV ${category.levelInfo.level}',
                style: AppText.unit(category.color, size: 12),
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

  /// Feuille d'action iOS : c'est ainsi qu'on présente un menu contextuel.
  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (contexte) => CupertinoActionSheet(
        title: Text(habit.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(contexte).pop('edit'),
            child: const Text('Modifier'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(contexte).pop('archive'),
            child: const Text('Archiver'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(contexte).pop(),
          child: const Text('Annuler'),
        ),
      ),
    );

    if (!context.mounted) return;
    switch (action) {
      case 'edit':
        await openHabitEditor(context, ref, habit: habit);
      case 'archive':
        await ref.read(appControllerProvider.notifier).archiveHabit(habit.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final serie = Streaks.of(data, habit);
    final taux = (serie.completionRate * 100).round();

    final label = CupertinoDynamicColor.resolve(AppTheme.label, context);
    final secondaire = CupertinoDynamicColor.resolve(
      AppTheme.secondaryLabel,
      context,
    );

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
                      Icon(CupertinoIcons.nosign, size: 14, color: secondaire),
                      Gaps.w4,
                    ],
                    Expanded(
                      child: Text(
                        habit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(label, size: 15),
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
                  style: AppText.caption(secondaire, size: 12),
                ),
                Gaps.h8,
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
                      style: AppText.caption(secondaire, size: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: () => _menu(context, ref),
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 18,
              color: secondaire,
              semanticLabel: 'Actions',
            ),
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
    final secondaire = CupertinoDynamicColor.resolve(
      AppTheme.secondaryLabel,
      context,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                habit.title,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(secondaire),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .archiveHabit(habit.id, archived: false),
              child: const Text('Réactiver', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
