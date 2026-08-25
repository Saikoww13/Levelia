import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        color: category.color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: category.color.withValues(alpha: 0.35)),
      ),
      child: Text(category.emoji, style: TextStyle(fontSize: size * 0.44)),
    );
  }
}

/// Barre de progression XP — style tableau de bord analytique.
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
  final String? label;
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
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'NIV ${info.level}',
                style: GoogleFonts.barlowCondensed(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label ?? info.rank,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              auMax
                  ? '${info.totalXp} XP'
                  : '${info.xpIntoLevel}/${info.xpForNextLevel}',
              style: GoogleFonts.barlowCondensed(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        _StatBar(
          progress: info.progress,
          color: color,
          height: compact ? 6 : 10,
        ),
      ],
    );
  }
}

/// Barre de stat avec repères visuels à 25 / 50 / 75 %.
class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.progress,
    required this.color,
    this.height = 10,
  });

  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // Background track
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: (width * progress.clamp(0.0, 1.0)),
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Tick marks at 25 / 50 / 75 %
              if (height >= 8)
                for (final pct in [0.25, 0.50, 0.75])
                  Positioned(
                    left: width * pct - 0.5,
                    child: Container(
                      width: 1,
                      height: height,
                      color: progress > pct
                          ? color.withValues(alpha: 0.3)
                          : color.withValues(alpha: 0.18),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Grand affichage de niveau pour la fiche de profil.
class LevelMedallion extends StatelessWidget {
  const LevelMedallion({super.key, required this.info, required this.color});

  final LevelInfo info;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress ring
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: info.progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          // Level number — dominant stat
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${info.level}',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              Text(
                info.rank.toUpperCase(),
                style: GoogleFonts.barlowCondensed(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pastille de série — icône flamme + nombre de jours.
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: couleur.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 12,
            color: couleur,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.barlowCondensed(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: couleur,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
