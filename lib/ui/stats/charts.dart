import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';

/// Grille de régularité : une case par jour, teintée selon la part
/// d'habitudes tenues ce jour-là.
///
/// Dessinée au [CustomPainter] plutôt qu'avec une bibliothèque de graphiques :
/// la forme est simple, et cela évite une dépendance de plus à maintenir.
class CompletionHeatmap extends StatelessWidget {
  const CompletionHeatmap({
    super.key,
    required this.ratios,
    required this.weeks,
    required this.color,
  });

  /// Taux de réussite par journée, indexé par [dayKey].
  final Map<String, double> ratios;

  /// Nombre de semaines affichées, de la plus ancienne à la semaine en cours.
  final int weeks;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final secondaire = c.secondary;
    final vide = c.separator.withValues(alpha: 0.55);

    final finSemaine = startOfWeek(today());
    final debut = finSemaine.subtract(Duration(days: 7 * (weeks - 1)));

    return LayoutBuilder(
      builder: (contexte, contraintes) {
        const espace = 3.0;
        final largeurColonne = (contraintes.maxWidth - 20) / weeks;
        final cote = (largeurColonne - espace).clamp(6.0, 18.0);
        final hauteur = 7 * (cote + espace);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: hauteur,
              child: CustomPaint(
                size: Size(contraintes.maxWidth, hauteur),
                painter: _HeatmapPainter(
                  ratios: ratios,
                  start: debut,
                  weeks: weeks,
                  cell: cote,
                  spacing: espace,
                  color: color,
                  emptyColor: vide,
                  todayOutline: color,
                ),
              ),
            ),
            Gaps.h8,
            Row(
              children: [
                Text(
                  shortDayLabel(debut),
                  style: AppText.caption(secondaire, size: 11),
                ),
                const Spacer(),
                Text('Moins', style: AppText.caption(secondaire, size: 11)),
                Gaps.w4,
                for (final niveau in [0.0, 0.34, 0.67, 1.0])
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: niveau == 0
                          ? vide
                          : color.withValues(alpha: 0.25 + niveau * 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Gaps.w4,
                Text('Plus', style: AppText.caption(secondaire, size: 11)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.ratios,
    required this.start,
    required this.weeks,
    required this.cell,
    required this.spacing,
    required this.color,
    required this.emptyColor,
    required this.todayOutline,
  });

  final Map<String, double> ratios;
  final DateTime start;
  final int weeks;
  final double cell;
  final double spacing;
  final Color color;
  final Color emptyColor;
  final Color todayOutline;

  @override
  void paint(Canvas canvas, Size size) {
    final peinture = Paint()..style = PaintingStyle.fill;
    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = todayOutline;

    final aujourdhui = today();

    for (var semaine = 0; semaine < weeks; semaine++) {
      for (var jourDeSemaine = 0; jourDeSemaine < 7; jourDeSemaine++) {
        final jour = start.add(Duration(days: semaine * 7 + jourDeSemaine));
        if (jour.isAfter(aujourdhui)) continue;

        final ratio = ratios[dayKey(jour)];
        peinture.color = ratio == null || ratio <= 0
            ? emptyColor
            : color.withValues(alpha: 0.25 + ratio.clamp(0, 1) * 0.75);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            semaine * (cell + spacing),
            jourDeSemaine * (cell + spacing),
            cell,
            cell,
          ),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, peinture);
        if (isSameDay(jour, aujourdhui)) canvas.drawRRect(rect, contour);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.ratios != ratios ||
      old.start != start ||
      old.weeks != weeks ||
      old.color != color ||
      old.emptyColor != emptyColor;
}

/// Histogramme : une barre par jour, avec sa valeur d'XP.
class DailyXpChart extends StatelessWidget {
  const DailyXpChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 110,
  });

  /// Valeurs dans l'ordre chronologique, associées à leur journée.
  final List<({DateTime day, int xp})> values;

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (values.isEmpty) return const SizedBox.shrink();

    final secondaire = c.secondary;
    final vide = c.separator.withValues(alpha: 0.7);

    final maximum = values.fold<int>(0, (m, v) => v.xp > m ? v.xp : m);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final valeur in values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      // Une barre à zéro reste visible sous forme de trait,
                      // pour que l'axe se lise même les jours vides.
                      height: maximum == 0
                          ? 2
                          : 2 + (valeur.xp / maximum) * (height - 6),
                      decoration: BoxDecoration(
                        color: valeur.xp == 0
                            ? vide
                            : color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Gaps.h8,
        Row(
          children: [
            Text(
              shortDayLabel(values.first.day),
              style: AppText.caption(secondaire, size: 11),
            ),
            const Spacer(),
            Text(
              'max $maximum XP',
              style: AppText.caption(secondaire, size: 11),
            ),
            const Spacer(),
            Text(
              shortDayLabel(values.last.day),
              style: AppText.caption(secondaire, size: 11),
            ),
          ],
        ),
      ],
    );
  }
}
