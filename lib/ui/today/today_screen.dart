import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../habits/habit_editor.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import '../widgets/xp_feedback.dart';
import 'habit_tile.dart';

/// L'écran du quotidien : ce qu'il y a à faire, et ce que ça rapporte.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final jour = ref.watch(selectedDayProvider);
    final entries = ref.watch(dayEntriesProvider);
    final avancement = ref.watch(dayProgressProvider);
    final xpDuJour = ref.watch(dayXpProvider);
    final theme = Theme.of(context);

    final estAujourdhui = isSameDay(jour, today());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(estAujourdhui ? 'Aujourd\'hui' : 'Journée passée'),
            Text(
              longDayLabel(jour),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (!estAujourdhui)
            TextButton.icon(
              onPressed: () =>
                  ref.read(selectedDayProvider.notifier).state = today(),
              icon: const Icon(Icons.today, size: 18),
              label: const Text('Revenir'),
            ),
          Gaps.w8,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openHabitEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Habitude'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _DaySummary(
              done: avancement.done,
              total: avancement.total,
              ratio: avancement.ratio,
              xpDuJour: xpDuJour,
            ),
            Gaps.h16,
            const _WeekStrip(),
            Gaps.h16,
            const _CategoryFilterBar(),
            Gaps.h16,
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.self_improvement,
                  title: data.activeHabits.isEmpty
                      ? 'Aucune habitude pour l\'instant'
                      : 'Rien de prévu ce jour-là',
                  message: data.activeHabits.isEmpty
                      ? 'Crée ta première habitude et commence à accumuler de l\'XP.'
                      : 'Aucune habitude n\'est planifiée ici. Change de jour ou ajuste la planification.',
                  action: FilledButton.icon(
                    onPressed: () => openHabitEditor(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une habitude'),
                  ),
                ),
              )
            else
              for (final entry in entries) ...[
                HabitTile(
                  entry: entry,
                  category: data.categoryById(entry.habit.categoryId),
                  onTap: () async {
                    final evenement = await ref
                        .read(appControllerProvider.notifier)
                        .cycleHabit(entry.habit, jour);
                    if (!context.mounted) return;
                    showXpFeedback(
                      context,
                      ref.read(appDataProvider),
                      evenement,
                    );
                  },
                ),
                Gaps.h8,
              ],
          ],
        ),
      ),
    );
  }
}

/// Bandeau de tête : progression de la journée et niveau global.
class _DaySummary extends ConsumerWidget {
  const _DaySummary({
    required this.done,
    required this.total,
    required this.ratio,
    required this.xpDuJour,
  });

  final int done;
  final int total;
  final double ratio;
  final int xpDuJour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final theme = Theme.of(context);
    final niveau = data.globalLevel;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: AlwaysStoppedAnimation(
                          ratio >= 1 ? AppTheme.success : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '$done/$total',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Gaps.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 0
                          ? 'Journée libre'
                          : done == total
                          ? 'Journée bouclée 💪'
                          : 'Il reste ${total - done} chose${total - done > 1 ? 's' : ''} à faire',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gaps.h4,
                    Text(
                      xpDuJour > 0
                          ? '+$xpDuJour XP gagnés ce jour'
                          : 'Aucun XP gagné pour l\'instant',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gaps.h16,
          const Divider(),
          Gaps.h12,
          XpBar(
            info: niveau,
            color: theme.colorScheme.primary,
            label: 'Niveau global · ${niveau.rank}',
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de journée sur la semaine en cours.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionne = ref.watch(selectedDayProvider);
    final theme = Theme.of(context);
    final jours = weekDays(selectionne);
    final aujourdhui = today();

    return Row(
      children: [
        for (final jour in jours)
          Expanded(
            child: _DayCell(
              day: jour,
              selected: isSameDay(jour, selectionne),
              isToday: isSameDay(jour, aujourdhui),
              // On ne pointe pas le futur : seul le passé se rattrape.
              enabled: !jour.isAfter(aujourdhui),
              onTap: () =>
                  ref.read(selectedDayProvider.notifier).state = jour,
              theme: theme,
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
    required this.theme,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final couleurTexte = !enabled
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
        : selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday && !selected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Text(
                weekdayLabelsShort[day.weekday - 1],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: couleurTexte.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: couleurTexte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtres par catégorie, en pastilles défilantes.
class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final filtre = ref.watch(categoryFilterProvider);
    final categories = data.activeCategories;

    if (categories.isEmpty) return const SizedBox.shrink();

    void choisir(String? id) =>
        ref.read(categoryFilterProvider.notifier).state = id;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Tout'),
            selected: filtre == null,
            onSelected: (_) => choisir(null),
          ),
          Gaps.w8,
          for (final Category categorie in categories) ...[
            FilterChip(
              avatar: Text(categorie.emoji),
              label: Text(categorie.name),
              selected: filtre == categorie.id,
              selectedColor: categorie.color.withValues(alpha: 0.22),
              onSelected: (choisi) => choisir(choisi ? categorie.id : null),
            ),
            Gaps.w8,
          ],
        ],
      ),
    );
  }
}
