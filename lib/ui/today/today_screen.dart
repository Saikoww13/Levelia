import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../habits/habit_editor.dart';
import '../widgets/category_widgets.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import '../widgets/xp_feedback.dart';
import 'habit_tile.dart';

/// L'écran du quotidien : ce qu'il y a à faire, et ce que ça rapporte.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final data = ref.watch(appDataProvider);
    final jour = ref.watch(selectedDayProvider);
    final entries = ref.watch(dayEntriesProvider);
    final avancement = ref.watch(dayProgressProvider);
    final xpDuJour = ref.watch(dayXpProvider);

    final estAujourdhui = isSameDay(jour, today());
    final secondaire = c.secondary;

    return AppPage(
      title: estAujourdhui ? 'Aujourd\'hui' : 'Journée passée',
      trailing: NavAddButton(
        onPressed: () => openHabitEditor(context, ref),
        semantic: 'Nouvelle habitude',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  longDayLabel(jour),
                  style: AppText.caption(secondaire),
                ),
              ),
              if (!estAujourdhui)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  onPressed: () =>
                      ref.read(selectedDayProvider.notifier).state = today(),
                  child: const Text(
                    'Aujourd\'hui',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
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
            padding: const EdgeInsets.only(top: 32),
            child: EmptyState(
              icon: CupertinoIcons.sparkles,
              title: data.activeHabits.isEmpty
                  ? 'Aucune habitude pour l\'instant'
                  : 'Rien de prévu ce jour-là',
              message: data.activeHabits.isEmpty
                  ? 'Crée ta première habitude et commence à accumuler de l\'XP.'
                  : 'Aucune habitude n\'est planifiée ici.',
              action: CupertinoButton.filled(
                onPressed: () => openHabitEditor(context, ref),
                child: const Text('Créer une habitude'),
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
                showXpFeedback(context, ref.read(appDataProvider), evenement);
              },
            ),
            Gaps.h8,
          ],
      ],
    );
  }
}

/// Carte de session — le tableau de bord de la journée.
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
    final c = AppColors.of(context);
    final data = ref.watch(appDataProvider);
    final niveau = data.globalLevel;
    final complete = done == total && total > 0;

    final label = c.label;
    final secondaire = c.secondary;
    final arc = complete ? AppTheme.success : AppTheme.seed;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                progress: total == 0 ? 0 : ratio,
                color: arc,
                size: 64,
                strokeWidth: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$done', style: AppText.readout(size: 20, color: arc)),
                    Text(
                      '/$total',
                      style: AppText.readout(
                        size: 11,
                        color: secondaire,
                        weight: FontWeight.w500,
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
                          : complete
                          ? 'Session complète'
                          : 'En cours',
                      style: AppText.title(
                        complete ? AppTheme.success : label,
                        size: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          xpDuJour > 0 ? '+$xpDuJour' : '0',
                          style: AppText.readout(
                            size: 26,
                            color: xpDuJour > 0 ? AppTheme.success : secondaire,
                          ),
                        ),
                        Gaps.w4,
                        Text('XP', style: AppText.unit(secondaire, size: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          XpBar(
            info: niveau,
            color: AppTheme.seed,
            label: 'Niveau global · ${niveau.rank}',
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de journée, avec navigation d'une semaine à l'autre.
///
/// Sans elle, un jour oublié il y a plus de sept jours devenait
/// définitivement inatteignable, alors que le modèle sait parfaitement
/// enregistrer un pointage à n'importe quelle date passée.
///
/// Changer de semaine déplace la journée sélectionnée du même nombre de jours
/// plutôt que de dissocier « semaine affichée » et « jour choisi » : une seule
/// source de vérité, et l'écran montre aussitôt les données de la semaine
/// atteinte.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  /// Décale la sélection de [semaines], sans jamais dépasser aujourd'hui.
  void _decaler(WidgetRef ref, int semaines) {
    final courant = ref.read(selectedDayProvider);
    final vise = courant.add(Duration(days: 7 * semaines));
    final aujourdhui = today();
    ref.read(selectedDayProvider.notifier).state = vise.isAfter(aujourdhui)
        ? aujourdhui
        : vise;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final selectionne = ref.watch(selectedDayProvider);
    final jours = weekDays(selectionne);
    final aujourdhui = today();

    // On ne va pas au-delà de la semaine en cours : il n'y a rien à y pointer.
    final semaineCourante = isSameDay(
      startOfWeek(selectionne),
      startOfWeek(aujourdhui),
    );

    return GestureDetector(
      // Le balayage horizontal fait la même chose que les chevrons : c'est le
      // geste attendu sur iPhone, les chevrons restent pour la découvrabilité.
      onHorizontalDragEnd: (details) {
        final vitesse = details.primaryVelocity ?? 0;
        if (vitesse > 240) {
          _decaler(ref, -1);
        } else if (vitesse < -240 && !semaineCourante) {
          _decaler(ref, 1);
        }
      },
      child: Row(
        children: [
          _WeekArrow(
            icon: CupertinoIcons.chevron_left,
            semantic: 'Semaine précédente',
            color: c.secondary,
            onTap: () => _decaler(ref, -1),
          ),
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
              ),
            ),
          _WeekArrow(
            icon: CupertinoIcons.chevron_right,
            semantic: 'Semaine suivante',
            color: c.secondary,
            // Désactivé sur la semaine en cours plutôt que masqué : la barre
            // garde la même largeur, les jours ne se décalent pas sous le doigt.
            onTap: semaineCourante ? null : () => _decaler(ref, 1),
          ),
        ],
      ),
    );
  }
}

/// Chevron de changement de semaine.
class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.icon,
    required this.semantic,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String semantic;
  final Color color;

  /// `null` désactive le chevron.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final actif = onTap != null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(28, 44),
      onPressed: onTap,
      child: Icon(
        icon,
        size: 16,
        color: actif
            ? color
            : CupertinoDynamicColor.resolve(AppTheme.tertiaryLabel, context),
        semanticLabel: semantic,
      ),
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
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final couleurTexte = !enabled
        ? c.tertiary
        : selected
        ? CupertinoColors.white
        : c.label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.seed : const Color(0x00000000),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday && !selected
                  ? AppTheme.seed.withValues(alpha: 0.6)
                  : const Color(0x00000000),
            ),
          ),
          child: Column(
            children: [
              Text(
                weekdayLabelsShort[day.weekday - 1],
                style: AppText.unit(
                  couleurTexte.withValues(alpha: 0.75),
                  size: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${day.day}',
                style: AppText.readout(size: 15, color: couleurTexte),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtres par catégorie, en capsules défilantes.
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
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          CategoryPill(
            label: 'Tout',
            selected: filtre == null,
            color: AppTheme.seed,
            onTap: () => choisir(null),
          ),
          Gaps.w8,
          for (final Category categorie in categories) ...[
            CategoryPill(
              label: categorie.name,
              emoji: categorie.emoji,
              selected: filtre == categorie.id,
              color: categorie.color,
              onTap: () =>
                  choisir(filtre == categorie.id ? null : categorie.id),
            ),
            Gaps.w8,
          ],
        ],
      ),
    );
  }
}
