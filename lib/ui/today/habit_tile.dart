import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';

/// Ligne d'habitude de l'écran du jour.
///
/// Un appui fait tourner l'état : à faire → réussi → manqué → à faire.
/// Les trois états sont distincts à dessein : « manqué » est une information
/// utile, différente de « pas encore pointé ».
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.entry,
    required this.category,
    required this.onTap,
  });

  final HabitEntry entry;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final habitude = entry.habit;
    final couleur = category?.color ?? AppTheme.seed;
    final label = c.label;
    final secondaire = c.secondary;

    final (icone, couleurEtat) = switch ((entry.isDone, entry.isMissed)) {
      (true, _) => (CupertinoIcons.checkmark_circle_fill, AppTheme.success),
      (_, true) => (CupertinoIcons.xmark_circle_fill, AppTheme.missed),
      _ => (CupertinoIcons.circle, c.tertiary),
    };

    final xpText = entry.isDone
        ? '+${entry.log!.xpAwarded}'
        : entry.isMissed && entry.log!.xpPenaltyApplied > 0
        ? '-${entry.log!.xpPenaltyApplied}'
        : '+${habitude.difficulty.xp}';

    final xpColor = entry.isDone
        ? AppTheme.success
        : entry.isMissed
        ? AppTheme.missed
        : couleur;

    return AppCard(
      onTap: onTap,
      accent: couleur,
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      child: Row(
        children: [
          Icon(icone, size: 26, color: couleurEtat),
          Gaps.w12,
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (habitude.isNegative) ...[
                      Icon(CupertinoIcons.nosign, size: 13, color: secondaire),
                      Gaps.w4,
                    ],
                    Expanded(
                      child: Text(
                        habitude.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.title(
                              entry.isMissed ? secondaire : label,
                              size: 15,
                            ).copyWith(
                              decoration: entry.isMissed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      habitude.schedule.label,
                      style: AppText.caption(secondaire, size: 12),
                    ),
                    if (entry.streak.current > 0)
                      StreakPill(label: entry.streak.currentLabel),
                  ],
                ),
              ],
            ),
          ),
          Gaps.w12,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(xpText, style: AppText.readout(size: 18, color: xpColor)),
              Text('XP', style: AppText.unit(secondaire)),
            ],
          ),
        ],
      ),
    );
  }
}
