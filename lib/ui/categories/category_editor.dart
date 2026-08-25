import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/seed.dart';
import '../../domain/models/category.dart';
import '../../state/providers.dart';
import '../widgets/sheet.dart';

/// Ouvre l'éditeur de catégorie, en création ou en modification.
Future<void> openCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  Category? category,
}) {
  return showAppSheet(
    context: context,
    title: category == null ? 'Nouvelle catégorie' : 'Modifier la catégorie',
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late String _emoji;
  late int _couleur;

  @override
  void initState() {
    super.initState();
    final categorie = widget.category;
    _nom = TextEditingController(text: categorie?.name ?? '');
    _emoji = categorie?.emoji ?? categoryEmojis.first;
    _couleur = categorie?.colorValue ?? categoryPalette.first;
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Text(_emoji, style: const TextStyle(fontSize: 26)),
              ),
              Gaps.w16,
              Expanded(
                child: TextFormField(
                  controller: _nom,
                  autofocus: widget.category == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nom du domaine',
                    hintText: 'Ex. : Sport, Finances, Créativité',
                  ),
                  validator: (valeur) =>
                      (valeur ?? '').trim().isEmpty ? 'Donne un nom' : null,
                ),
              ),
            ],
          ),

          Gaps.h24,
          Text(
            'SYMBOLE',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Gaps.h8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final emoji in categoryEmojis)
                GestureDetector(
                  onTap: () => setState(() => _emoji = emoji),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _emoji == emoji
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      border: Border.all(
                        color: _emoji == emoji
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),

          Gaps.h24,
          Text(
            'COULEUR',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Gaps.h8,
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final valeur in categoryPalette)
                GestureDetector(
                  onTap: () => setState(() => _couleur = valeur),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(valeur),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _couleur == valeur
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _couleur == valeur
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
            ],
          ),

          Gaps.h32,
          Row(
            children: [
              if (widget.category != null)
                TextButton.icon(
                  onPressed: _confirmerSuppression,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _enregistrer,
                child: Text(widget.category == null ? 'Créer' : 'Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerSuppression() async {
    final categorie = widget.category!;
    final data = ref.read(appDataProvider);
    final habitudes = data.habitsOf(categorie.id).length;
    final objectifs = data.goalsOf(categorie.id).length;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: Text('Supprimer « ${categorie.name} » ?'),
        content: Text(
          'Cette action effacera $habitudes habitude(s), $objectifs objectif(s) '
          'et les ${categorie.xp} XP du domaine. Ton niveau global baissera d\'autant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexte).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;
    await ref.read(appControllerProvider.notifier).deleteCategory(categorie.id);
    if (mounted) Navigator.of(context).pop();
  }
}
