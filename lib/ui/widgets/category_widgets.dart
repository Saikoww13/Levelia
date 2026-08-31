import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/category.dart';

/// Pastille ronde d'un domaine : son emoji sur son fond coloré.
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
      child: Text(category.emoji, style: AppText.emoji(size * 0.44)),
    );
  }
}

/// Capsule sélectionnable, dans l'esprit des pastilles d'iOS.
///
/// Sert partout où l'on choisit ou filtre par domaine : barre de filtres de la
/// journée, et sélecteur de domaine des deux éditeurs. Elle existait en trois
/// exemplaires — deux classes privées et une version écrite en ligne — qui
/// divergeaient déjà sur les couleurs de fond.
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.emoji,
    this.background,
  });

  final String label;
  final bool selected;

  /// Teinte du domaine, appliquée quand la capsule est sélectionnée.
  final Color color;

  final VoidCallback onTap;

  /// Emoji affiché avant le libellé. Absent pour la capsule « Tout ».
  final String? emoji;

  /// Fond au repos. Par défaut celui d'une carte ; les formulaires passent
  /// celui d'un champ pour rester cohérents avec les zones de saisie voisines.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final teinteTexte = selected ? color : c.secondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : (background ?? c.card),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.45) : c.separator,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: AppText.emoji(14)),
              Gaps.w4,
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'CupertinoSystemText',
                fontSize: 14,
                letterSpacing: -0.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: teinteTexte,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choix d'un domaine parmi ceux qui existent, en capsules.
///
/// Bloc commun aux éditeurs d'habitude et d'objectif, où il était écrit deux
/// fois à l'identique.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final categorie in categories)
          CategoryPill(
            label: categorie.name,
            emoji: categorie.emoji,
            color: categorie.color,
            selected: selectedId == categorie.id,
            background: c.field,
            onTap: () => onSelected(categorie.id),
          ),
      ],
    );
  }
}
