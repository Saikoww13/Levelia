import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/leveling.dart';
import 'common.dart';

/// Barre de progression d'XP : niveau à gauche, reste à parcourir à droite.
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
    final c = AppColors.of(context);
    final secondaire = c.secondary;
    final auMax = info.xpForNextLevel <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'NIV ${info.level}',
                style: AppText.unit(color, size: compact ? 11 : 12),
              ),
            ),
            Gaps.w8,
            Expanded(
              child: Text(
                label ?? info.rank,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption(secondaire, size: 12),
              ),
            ),
            Text(
              auMax
                  ? '${info.totalXp} XP'
                  : '${info.xpIntoLevel}/${info.xpForNextLevel}',
              style: AppText.readout(
                size: 13,
                color: secondaire,
                weight: FontWeight.w500,
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
        final largeur = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Container(
                width: largeur,
                height: height,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: largeur * progress.clamp(0.0, 1.0),
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              if (height >= 8)
                for (final pct in [0.25, 0.50, 0.75])
                  Positioned(
                    left: largeur * pct - 0.5,
                    child: Container(
                      width: 1,
                      height: height,
                      color: color.withValues(
                        alpha: progress > pct ? 0.3 : 0.18,
                      ),
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
    final c = AppColors.of(context);
    final secondaire = c.secondary;

    return ProgressRing(
      progress: info.progress,
      color: color,
      size: 120,
      strokeWidth: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${info.level}',
            style: AppText.readout(size: 48, color: color, letterSpacing: -1),
          ),
          Text(
            info.rank.toUpperCase(),
            style: AppText.unit(secondaire).copyWith(letterSpacing: 1.6),
          ),
        ],
      ),
    );
  }
}

/// Pastille de série — flamme et durée.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.label, this.active = true});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final couleur = active ? AppTheme.streak : c.secondary;

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
          Icon(CupertinoIcons.flame_fill, size: 11, color: couleur),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppText.readout(
              size: 12,
              color: couleur,
              weight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contrôle segmenté glissant, au format iOS, avec l'étiquette de groupe.
///
/// Remplace le SegmentedButton de Material : sur iOS, un choix parmi quelques
/// options se fait avec un segmenté glissant, jamais avec des boutons cochés.
class AppSegmented<T extends Object> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.value,
    required this.children,
    required this.onChanged,
  });

  final T value;
  final Map<T, Widget> children;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor: c.field,
        thumbColor: c.card,
        padding: const EdgeInsets.all(3),
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
        children: children,
      ),
    );
  }
}

/// Libellé d'un segment : texte principal, et sous-titre chiffré facultatif.
class SegmentLabel extends StatelessWidget {
  const SegmentLabel(this.text, {super.key, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = c.label;
    final secondaire = c.secondary;

    // Pas de rembourrage vertical : le contrôle segmenté d'iOS fixe lui-même
    // sa hauteur, et un libellé à deux lignes la dépasse sinon.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppText.body(label, size: 13).copyWith(height: 1.15),
        ),
        if (detail != null)
          Text(
            detail!,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: AppText.readout(
              size: 11,
              color: secondaire,
              weight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
