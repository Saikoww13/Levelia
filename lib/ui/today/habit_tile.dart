import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';

/// Ligne d'habitude de l'écran du jour.
///
/// Un appui fait tourner l'état : à faire → réussi → manqué → à faire.
/// Les trois états sont distincts à dessein : « manqué » est une information
/// utile, différente de « pas encore renseigné ».
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.entry,
    required this.category,
    required this.onTap,
    this.onLongPress,
  });

  final HabitEntry entry;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitude = entry.habit;
    final couleur = category?.color ?? theme.colorScheme.primary;

    final (icone, couleurEtat) = switch ((entry.isDone, entry.isMissed)) {
      (true, _) => (Icons.check_circle, AppTheme.success),
      (_, true) => (Icons.cancel, AppTheme.missed),
      _ => (Icons.radio_button_unchecked, theme.colorScheme.outline),
    };

    return AppCard(
      onTap: onTap,
      accent: couleur,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(icone, size: 30, color: couleurEtat),
            tooltip: entry.isDone
                ? 'Marquer comme manqué'
                : entry.isMissed
                ? 'Effacer le pointage'
                : 'Marquer ${habitude.doneLabel.toLowerCase()}',
          ),
          Gaps.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (habitude.isNegative) ...[
                      Icon(
                        Icons.block,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Gaps.w4,
                    ],
                    Expanded(
                      child: Text(
                        habitude.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: entry.isMissed
                              ? TextDecoration.lineThrough
                              : null,
                          color: entry.isMissed
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.h4,
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      habitude.schedule.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (entry.streak.current > 0)
                      StreakPill(label: entry.streak.currentLabel),
                  ],
                ),
              ],
            ),
          ),
          Gaps.w8,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.isDone && entry.log != null
                    ? '+${entry.log!.xpAwarded}'
                    : '+${habitude.difficulty.xp}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: entry.isDone ? AppTheme.success : couleur,
                ),
              ),
              Text(
                'XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
