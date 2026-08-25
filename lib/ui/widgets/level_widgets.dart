import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/leveling.dart';
import '../../domain/models/category.dart';

/// Pastille ronde d'une catégorie : son emoji sur son fond coloré.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 40});

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: category.color.withValues(alpha: 0.45)),
      ),
      child: Text(category.emoji, style: TextStyle(fontSize: size * 0.46)),
    );
  }
}

/// Barre de progression d'XP, avec le niveau à gauche et le reste à parcourir.
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.info,
    required this.color,
    this.label,
    this.compact = false,
  });

  final LevelInfo info;
  final Color color;

  /// Texte affiché au-dessus de la barre. Par défaut, le rang.
  final String? label;

  /// Version resserrée, pour les listes.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auMax = info.xpForNextLevel <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Niv. ${info.level}',
              style: (compact
                      ? theme.textTheme.labelMedium
                      : theme.textTheme.titleSmall)
                  ?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
            Gaps.w8,
            Expanded(
              child: Text(
                label ?? info.rank,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              auMax
                  ? '${info.totalXp} XP'
                  : '${info.xpIntoLevel} / ${info.xpForNextLevel} XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: info.progress,
            minHeight: compact ? 6 : 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// Grand médaillon de niveau, utilisé sur la fiche de profil.
class LevelMedallion extends StatelessWidget {
  const LevelMedallion({super.key, required this.info, required this.color});

  final LevelInfo info;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: CircularProgressIndicator(
              value: info.progress,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NIVEAU',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${info.level}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petite étiquette « 🔥 12 jours ».
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.label, this.active = true});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = active
        ? AppTheme.streak
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? '🔥 $label' : label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: couleur,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
