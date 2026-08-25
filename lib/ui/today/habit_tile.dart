import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';

/// Ligne d'habitude — canal de la session du jour.
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
          // State toggle icon
          GestureDetector(
            onTap: onTap,
            child: Icon(icone, size: 28, color: couleurEtat),
          ),
          Gaps.w12,
          // Category dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: couleur,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // Habit name + meta
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
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Gaps.w4,
                    ],
                    Expanded(
                      child: Text(
                        habitude.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: entry.isMissed
                              ? TextDecoration.lineThrough
                              : null,
                          color: entry.isMissed
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
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
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (entry.streak.current > 0)
                      StreakPill(label: entry.streak.currentLabel),
                  ],
                ),
              ],
            ),
          ),
          Gaps.w12,
          // XP readout
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                xpText,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: xpColor,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'XP',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
