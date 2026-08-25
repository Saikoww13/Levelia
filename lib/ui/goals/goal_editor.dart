import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/goal.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/sheet.dart';

/// Ouvre l'éditeur d'objectif, en création ou en modification.
Future<void> openGoalEditor(
  BuildContext context,
  WidgetRef ref, {
  Goal? goal,
}) {
  final data = ref.read(appDataProvider);
  if (data.activeCategories.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crée d\'abord une catégorie dans l\'onglet Profil.'),
      ),
    );
    return Future.value();
  }

  return showAppSheet(
    context: context,
    title: goal == null ? 'Nouvel objectif' : 'Modifier l\'objectif',
    builder: (_) => _GoalEditor(goal: goal),
  );
}

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({this.goal});

  final Goal? goal;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

/// Une étape en cours d'édition, avec son contrôleur de saisie.
class _MilestoneDraft {
  _MilestoneDraft({required this.id, required String title, this.done = false})
    : controller = TextEditingController(text: title);

  final String id;
  final TextEditingController controller;
  final bool done;
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titre;
  late final TextEditingController _description;

  late String _categorieId;
  DateTime? _echeance;
  late List<_MilestoneDraft> _etapes;

  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    final objectif = widget.goal;
    final data = ref.read(appDataProvider);

    _titre = TextEditingController(text: objectif?.title ?? '');
    _description = TextEditingController(text: objectif?.description ?? '');
    _categorieId = objectif?.categoryId ?? data.activeCategories.first.id;
    _echeance = objectif?.targetDate;
    _etapes = [
      for (final m in objectif?.milestones ?? const <Milestone>[])
        _MilestoneDraft(id: m.id, title: m.title, done: m.done),
    ];
    if (_etapes.isEmpty) _etapes = [_MilestoneDraft(id: _uuid.v4(), title: '')];
  }

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    for (final etape in _etapes) {
      etape.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirEcheance() async {
    final maintenant = today();
    final choisie = await showDatePicker(
      context: context,
      initialDate: _echeance ?? maintenant.add(const Duration(days: 30)),
      firstDate: maintenant.subtract(const Duration(days: 365)),
      lastDate: maintenant.add(const Duration(days: 365 * 10)),
      helpText: 'Échéance de l\'objectif',
    );
    if (choisie != null) setState(() => _echeance = dayOf(choisie));
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enregistrement = true);
    try {
      final controleur = ref.read(appControllerProvider.notifier);
      final existant = widget.goal;

      final etapes = [
        for (final brouillon in _etapes)
          if (brouillon.controller.text.trim().isNotEmpty)
            Milestone(
              id: brouillon.id,
              title: brouillon.controller.text.trim(),
              done: brouillon.done,
            ),
      ];

      if (existant == null) {
        await controleur.addGoal(
          title: _titre.text,
          categoryId: _categorieId,
          description: _description.text,
          targetDate: _echeance,
          milestoneTitles: etapes.map((m) => m.title).toList(),
        );
      } else {
        await controleur.updateGoal(
          existant.copyWith(
            title: _titre.text.trim(),
            description: _description.text.trim(),
            categoryId: _categorieId,
            targetDate: _echeance,
            clearTargetDate: _echeance == null,
            milestones: etapes,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titre,
            autofocus: widget.goal == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Objectif',
              hintText: 'Ex. : courir 10 km d\'affilée',
            ),
            validator: (valeur) =>
                (valeur ?? '').trim().isEmpty ? 'Donne un titre' : null,
          ),
          Gaps.h12,
          TextFormField(
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Pourquoi (facultatif)',
              hintText: 'Ce qui te motive, ou comment tu comptes t\'y prendre',
            ),
          ),

          Gaps.h24,
          const FormLabel('Catégorie'),
          Gaps.h8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final categorie in data.activeCategories)
                ChoiceChip(
                  avatar: Text(categorie.emoji),
                  label: Text(categorie.name),
                  selected: _categorieId == categorie.id,
                  selectedColor: categorie.color.withValues(alpha: 0.22),
                  onSelected: (_) =>
                      setState(() => _categorieId = categorie.id),
                ),
            ],
          ),

          Gaps.h24,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _choisirEcheance,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    _echeance == null
                        ? 'Ajouter une échéance'
                        : 'Échéance : ${shortDayLabel(_echeance!)}',
                  ),
                ),
              ),
              if (_echeance != null)
                IconButton(
                  tooltip: 'Retirer l\'échéance',
                  onPressed: () => setState(() => _echeance = null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),

          Gaps.h24,
          Row(
            children: [
              const Expanded(child: FormLabel('Étapes')),
              Text(
                '+${Milestone.xpReward} XP chacune',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Gaps.h8,
          for (var i = 0; i < _etapes.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _etapes[i].controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Étape ${i + 1}',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retirer cette étape',
                    onPressed: _etapes.length == 1
                        ? null
                        : () {
                            _etapes[i].controller.dispose();
                            setState(() => _etapes.removeAt(i));
                          },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(
              () => _etapes.add(_MilestoneDraft(id: _uuid.v4(), title: '')),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter une étape'),
          ),

          Gaps.h32,
          Row(
            children: [
              if (widget.goal != null)
                TextButton.icon(
                  onPressed: _enregistrement ? null : _confirmerSuppression,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _enregistrement ? null : _enregistrer,
                child: Text(widget.goal == null ? 'Créer' : 'Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerSuppression() async {
    final objectif = widget.goal!;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: const Text('Supprimer cet objectif ?'),
        content: Text('« ${objectif.title} » sera définitivement effacé.'),
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
    await ref.read(appControllerProvider.notifier).deleteGoal(objectif.id);
    if (mounted) Navigator.of(context).pop();
  }
}
