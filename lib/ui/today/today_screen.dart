import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../habits/habit_editor.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import '../widgets/xp_feedback.dart';
import 'habit_tile.dart';

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
                letterSpacing: 0.3,
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
            _SessionCard(
              done: avancement.done,
              total: avancement.total,
              ratio: avancement.ratio,
              xpDuJour: xpDuJour,
            ),
            Gaps.h12,
            const _WeekStrip(),
            Gaps.h12,
            const _CategoryFilterBar(),
            Gaps.h12,
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
                      : 'Aucune habitude n\'est planifiée ici.',
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

/// Carte de session — scorecard du jour.
class _SessionCard extends ConsumerWidget {
  const _SessionCard({
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
    final complete = done == total && total > 0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: two stat columns
          Row(
            children: [
              // Completion arc + stat
              _CompletionArc(
                done: done,
                total: total,
                ratio: ratio,
                complete: complete,
                theme: theme,
              ),
              Gaps.w16,
              // Right column: label + XP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 0
                          ? 'Journée libre'
                          : complete
                          ? 'Session complète'
                          : 'En cours',
                      style: GoogleFonts.barlow(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: complete
                            ? AppTheme.success
                            : theme.colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          xpDuJour > 0 ? '+$xpDuJour' : '0',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: xpDuJour > 0
                                ? AppTheme.success
                                : theme.colorScheme.onSurfaceVariant,
                            height: 1.0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Gaps.w4,
                        Text(
                          'XP',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // XP level bar
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

class _CompletionArc extends StatelessWidget {
  const _CompletionArc({
    required this.done,
    required this.total,
    required this.ratio,
    required this.complete,
    required this.theme,
  });

  final int done;
  final int total;
  final double ratio;
  final bool complete;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final arcColor =
        complete ? AppTheme.success : theme.colorScheme.primary;

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : ratio,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: arcColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(arcColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: arcColor,
                  height: 1.0,
                ),
              ),
              Text(
                '/$total',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de journée sur 7 jours.
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
    final textColor = !enabled
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
        : selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday && !selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Text(
                weekdayLabelsShort[day.weekday - 1],
                style: GoogleFonts.barlowCondensed(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.7),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtres par catégorie.
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
      height: 36,
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
              selectedColor: categorie.color.withValues(alpha: 0.2),
              onSelected: (choisi) => choisir(choisi ? categorie.id : null),
            ),
            Gaps.w8,
          ],
        ],
      ),
    );
  }
}

