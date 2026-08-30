import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/engine/streaks.dart';
import '../../domain/models/app_data.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import 'charts.dart';

/// Nombre de semaines couvertes par la grille de régularité.
const int _heatmapWeeks = 16;

/// Nombre de jours de l'histogramme d'XP.
const int _xpChartDays = 14;

/// Toutes les statistiques dérivées de l'historique, calculées d'un bloc.
class StatsSnapshot {
  const StatsSnapshot({
    required this.dailyRatios,
    required this.dailyXp,
    required this.bestStreak,
    required this.bestStreakLabel,
    required this.completionRate30,
    required this.totalDone,
    required this.activeDays,
  });

  /// Taux de réussite par journée, pour la grille.
  final Map<String, double> dailyRatios;

  /// XP gagnée par journée sur la période récente.
  final List<({DateTime day, int xp})> dailyXp;

  final int bestStreak;
  final String bestStreakLabel;

  /// Taux de réussite sur les 30 derniers jours.
  final double completionRate30;

  final int totalDone;

  /// Nombre de journées où au moins une habitude a été tenue.
  final int activeDays;
}

final statsProvider = Provider<StatsSnapshot>((ref) {
  final data = ref.watch(appDataProvider);
  return _computeStats(data);
});

StatsSnapshot _computeStats(AppData data) {
  final fin = today();
  final debutGrille = startOfWeek(
    fin,
  ).subtract(Duration(days: 7 * (_heatmapWeeks - 1)));

  final ratios = <String, double>{};
  final habitudes = data.activeHabits;

  var attendus30 = 0;
  var reussis30 = 0;
  final debut30 = fin.subtract(const Duration(days: 29));

  for (
    var jour = debutGrille;
    !jour.isAfter(fin);
    jour = jour.add(const Duration(days: 1))
  ) {
    var dus = 0;
    var faits = 0;

    for (final habitude in habitudes) {
      if (jour.isBefore(dayOf(habitude.createdAt))) continue;
      if (!habitude.schedule.isDueOn(jour)) continue;
      dus++;
      final log = data.logFor(habitude.id, jour);
      if (log != null && log.done) faits++;
    }

    if (dus > 0) {
      ratios[dayKey(jour)] = faits / dus;
      if (!jour.isBefore(debut30)) {
        attendus30 += dus;
        reussis30 += faits;
      }
    }
  }

  // XP par journée sur la fenêtre récente.
  final xpParJour = <String, int>{};
  var totalFaits = 0;
  final joursActifs = <String>{};
  for (final log in data.logs.values) {
    if (!log.done) continue;
    totalFaits++;
    final cle = dayKey(log.day);
    joursActifs.add(cle);
    xpParJour[cle] = (xpParJour[cle] ?? 0) + log.xpAwarded;
  }

  final serieXp = <({DateTime day, int xp})>[];
  for (var i = _xpChartDays - 1; i >= 0; i--) {
    final jour = fin.subtract(Duration(days: i));
    serieXp.add((day: jour, xp: xpParJour[dayKey(jour)] ?? 0));
  }

  // Meilleure série, toutes habitudes confondues.
  var meilleure = 0;
  var libelle = '0 jour';
  for (final habitude in habitudes) {
    final serie = Streaks.of(data, habitude);
    if (serie.best > meilleure) {
      meilleure = serie.best;
      libelle = serie.bestLabel;
    }
  }

  return StatsSnapshot(
    dailyRatios: ratios,
    dailyXp: serieXp,
    bestStreak: meilleure,
    bestStreakLabel: libelle,
    completionRate30: attendus30 == 0 ? 0 : reussis30 / attendus30,
    totalDone: totalFaits,
    activeDays: joursActifs.length,
  );
}

/// L'écran de progression : où en est-on, et depuis quand.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final stats = ref.watch(statsProvider);
    final niveau = data.globalLevel;

    final label = CupertinoDynamicColor.resolve(AppTheme.label, context);
    final secondaire = CupertinoDynamicColor.resolve(
      AppTheme.secondaryLabel,
      context,
    );

    return AppPage(
      title: 'Progression',
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Hauteur fixe plutôt qu'un rapport largeur/hauteur : les compteurs
          // gardent la même allure quelle que soit la largeur de la fenêtre.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 128,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          children: [
            StatTile(
              value: '${data.totalXp}',
              label: 'XP au total',
              icon: CupertinoIcons.bolt_fill,
              color: AppTheme.seed,
            ),
            StatTile(
              value: 'NIV ${niveau.level}',
              label: niveau.rank,
              icon: CupertinoIcons.rosette,
              color: AppTheme.streak,
            ),
            StatTile(
              value: stats.bestStreakLabel,
              label: 'Meilleure série',
              icon: CupertinoIcons.flame_fill,
              color: AppTheme.streak,
            ),
            StatTile(
              value: '${(stats.completionRate30 * 100).round()} %',
              label: 'Réussite sur 30 j',
              icon: CupertinoIcons.chart_pie_fill,
              color: AppTheme.success,
            ),
          ],
        ),

        Gaps.h24,
        const SectionTitle(title: 'Régularité'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${plural(stats.totalDone, 'journée tenue', 'journées tenues')} '
                'sur ${plural(stats.activeDays, 'jour')} d\'activité',
                style: AppText.caption(secondaire),
              ),
              Gaps.h16,
              CompletionHeatmap(
                ratios: stats.dailyRatios,
                weeks: _heatmapWeeks,
                color: AppTheme.seed,
              ),
            ],
          ),
        ),

        Gaps.h24,
        const SectionTitle(title: 'XP des 14 derniers jours'),
        AppCard(
          child: DailyXpChart(values: stats.dailyXp, color: AppTheme.seed),
        ),

        Gaps.h24,
        const SectionTitle(title: 'Niveau par domaine'),
        if (data.activeCategories.isEmpty)
          AppCard(
            child: Text('Aucun domaine.', style: AppText.body(secondaire)),
          )
        else
          for (final categorie in data.activeCategories) ...[
            AppCard(
              accent: categorie.color,
              child: Row(
                children: [
                  CategoryAvatar(category: categorie, size: 38),
                  Gaps.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categorie.name,
                          style: AppText.title(label, size: 15),
                        ),
                        Gaps.h8,
                        XpBar(
                          info: categorie.levelInfo,
                          color: categorie.color,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gaps.h8,
          ],
      ],
    );
  }
}
