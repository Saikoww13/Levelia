import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/seed.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/modal_page.dart';

/// Ouvre l'éditeur de domaine, en création ou en modification.
Future<void> openCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  Category? category,
}) {
  return showAppModal<void>(
    context: context,
    builder: (_) => _CategoryEditor(category: category),
  );
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({this.category});

  final Category? category;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _nom;
  late String _emoji;
  late int _couleur;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    final categorie = widget.category;
    _nom = TextEditingController(text: categorie?.name ?? '')
      ..addListener(() => setState(() {}));
    _emoji = categorie?.emoji ?? categoryEmojis.first;
    _couleur = categorie?.colorValue ?? categoryPalette.first;
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    setState(() => _enregistrement = true);
    try {
      final controleur = ref.read(appControllerProvider.notifier);
      final existante = widget.category;

      if (existante == null) {
        await controleur.addCategory(
          name: _nom.text,
          emoji: _emoji,
          colorValue: _couleur,
        );
      } else {
        await controleur.updateCategory(
          existante.copyWith(
            name: _nom.text.trim(),
            emoji: _emoji,
            colorValue: _couleur,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _enregistrement = false);
      await showNotice(
        context,
        title: 'Enregistrement impossible',
        message:
            'Tes données n\'ont pas pu être écrites sur l\'appareil.\n\n$erreur',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final valide = _nom.text.trim().isNotEmpty;

    return AppFormPage(
      title: widget.category == null ? 'Nouveau domaine' : 'Modifier',
      actionLabel: widget.category == null ? 'Créer' : 'OK',
      onAction: valide && !_enregistrement ? _enregistrer : null,
      onDelete: widget.category == null ? null : _confirmerSuppression,
      deleteLabel: 'Supprimer le domaine',
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(_couleur).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(_couleur).withValues(alpha: 0.5),
                ),
              ),
              child: Text(_emoji, style: AppText.emoji(26)),
            ),
            Gaps.w16,
            Expanded(
              child: AppTextField(
                controller: _nom,
                placeholder: 'Ex. : Sport, Finances, Créativité',
                autofocus: widget.category == null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),

        Gaps.h24,
        const FormLabel('Symbole'),
        Gaps.h8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final emoji in categoryEmojis)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _emoji = emoji),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: _emoji == emoji
                        ? AppTheme.seed.withValues(alpha: 0.16)
                        : CupertinoDynamicColor.resolve(
                            AppTheme.field,
                            context,
                          ),
                    border: Border.all(
                      color: _emoji == emoji
                          ? AppTheme.seed
                          : CupertinoDynamicColor.resolve(
                              AppTheme.separator,
                              context,
                            ),
                      width: _emoji == emoji ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(emoji, style: AppText.emoji(20)),
                ),
              ),
          ],
        ),

        Gaps.h24,
        const FormLabel('Couleur'),
        Gaps.h8,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final valeur in categoryPalette)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _couleur = valeur),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(valeur),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _couleur == valeur
                          ? CupertinoDynamicColor.resolve(
                              AppTheme.label,
                              context,
                            )
                          : const Color(0x00000000),
                      width: 3,
                    ),
                  ),
                  child: _couleur == valeur
                      ? const Icon(
                          CupertinoIcons.check_mark,
                          color: CupertinoColors.white,
                          size: 20,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmerSuppression() async {
    final categorie = widget.category!;
    final data = ref.read(appDataProvider);
    final habitudes = data.habitsOf(categorie.id).length;
    final objectifs = data.goalsOf(categorie.id).length;

    final confirme = await confirmDestructive(
      context,
      title: 'Supprimer « ${categorie.name} » ?',
      message:
          'Cette action effacera $habitudes habitude(s), $objectifs objectif(s) '
          'et les ${categorie.xp} XP du domaine. Ton niveau global baissera d\'autant.',
    );

    if (!confirme || !mounted) return;
    await ref.read(appControllerProvider.notifier).deleteCategory(categorie.id);
    if (mounted) Navigator.of(context).pop();
  }
}
