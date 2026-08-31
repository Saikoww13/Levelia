import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/goal.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/modal_page.dart';

/// Ouvre l'éditeur d'objectif, en création ou en modification.
Future<void> openGoalEditor(
  BuildContext context,
  WidgetRef ref, {
  Goal? goal,
}) async {
  final data = ref.read(appDataProvider);
  if (data.activeCategories.isEmpty) {
    return showNotice(
      context,
      title: 'Aucun domaine',
      message: 'Crée d\'abord un domaine dans l\'onglet Profil.',
    );
  }

  return showAppModal<void>(
    context: context,
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

    _titre = TextEditingController(text: objectif?.title ?? '')
      ..addListener(() => setState(() {}));
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

  /// Sélecteur de date iOS : une roue dans une feuille montante.
  Future<void> _choisirEcheance() async {
    final maintenant = today();
    var choisie = _echeance ?? maintenant.add(const Duration(days: 30));

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (contexte) => Container(
        height: 300,
        color: CupertinoDynamicColor.resolve(AppTheme.card, contexte),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(contexte).pop(),
                    child: const Text('Annuler'),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      setState(() => _echeance = dayOf(choisie));
                      Navigator.of(contexte).pop();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: choisie,
                  minimumDate: maintenant.subtract(const Duration(days: 365)),
                  maximumDate: maintenant.add(const Duration(days: 365 * 10)),
                  onDateTimeChanged: (d) => choisie = d,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _valide => _titre.text.trim().isNotEmpty;

  Future<void> _enregistrer() async {
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
    final data = ref.watch(appDataProvider);
    final label = CupertinoDynamicColor.resolve(AppTheme.label, context);
    final secondaire = CupertinoDynamicColor.resolve(
      AppTheme.secondaryLabel,
      context,
    );

    return AppFormPage(
      title: widget.goal == null ? 'Nouvel objectif' : 'Modifier',
      actionLabel: widget.goal == null ? 'Créer' : 'OK',
      onAction: _valide && !_enregistrement ? _enregistrer : null,
      onDelete: widget.goal == null ? null : _confirmerSuppression,
      deleteLabel: 'Supprimer l\'objectif',
      children: [
        AppTextField(
          controller: _titre,
          placeholder: 'Ex. : courir 10 km d\'affilée',
          autofocus: widget.goal == null,
        ),
        Gaps.h8,
        AppTextField(
          controller: _description,
          placeholder: 'Pourquoi (facultatif)',
          maxLines: 3,
        ),

        Gaps.h24,
        const FormLabel('Domaine'),
        Gaps.h8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final categorie in data.activeCategories)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _categorieId = categorie.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _categorieId == categorie.id
                        ? categorie.color.withValues(alpha: 0.16)
                        : CupertinoDynamicColor.resolve(
                            AppTheme.field,
                            context,
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _categorieId == categorie.id
                          ? categorie.color.withValues(alpha: 0.45)
                          : CupertinoDynamicColor.resolve(
                              AppTheme.separator,
                              context,
                            ),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(categorie.emoji, style: AppText.emoji(14)),
                      Gaps.w4,
                      Text(
                        categorie.name,
                        style: TextStyle(
                          fontFamily: 'CupertinoSystemText',
                          fontSize: 14,
                          letterSpacing: -0.2,
                          fontWeight: _categorieId == categorie.id
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _categorieId == categorie.id
                              ? categorie.color
                              : secondaire,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        Gaps.h24,
        const FormLabel('Échéance'),
        Gaps.h8,
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: _choisirEcheance,
                  child: Text(
                    _echeance == null
                        ? 'Aucune échéance'
                        : shortDayLabel(_echeance!),
                    style: AppText.body(_echeance == null ? secondaire : label),
                  ),
                ),
              ),
              if (_echeance != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  onPressed: () => setState(() => _echeance = null),
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 18,
                    color: secondaire,
                    semanticLabel: 'Retirer l\'échéance',
                  ),
                ),
            ],
          ),
        ),

        Gaps.h24,
        Row(
          children: [
            const Expanded(child: FormLabel('Étapes')),
            Text(
              '+${Milestone.xpReward} XP chacune',
              style: AppText.caption(secondaire, size: 12),
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
                  child: AppTextField(
                    controller: _etapes[i].controller,
                    placeholder: 'Étape ${i + 1}',
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 40),
                  onPressed: _etapes.length == 1
                      ? null
                      : () {
                          final retiree = _etapes.removeAt(i);
                          retiree.controller.dispose();
                          setState(() {});
                        },
                  child: Icon(
                    CupertinoIcons.minus_circle,
                    size: 20,
                    color: _etapes.length == 1
                        ? CupertinoDynamicColor.resolve(
                            AppTheme.tertiaryLabel,
                            context,
                          )
                        : AppTheme.missed,
                    semanticLabel: 'Retirer cette étape',
                  ),
                ),
              ],
            ),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          minimumSize: const Size(0, 36),
          onPressed: () => setState(
            () => _etapes.add(_MilestoneDraft(id: _uuid.v4(), title: '')),
          ),
          child: const Text(
            'Ajouter une étape',
            style: TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmerSuppression() async {
    final objectif = widget.goal!;
    final confirme = await confirmDestructive(
      context,
      title: 'Supprimer cet objectif ?',
      message: '« ${objectif.title} » sera définitivement effacé.',
    );

    if (!confirme || !mounted) return;
    await ref.read(appControllerProvider.notifier).deleteGoal(objectif.id);
    if (mounted) Navigator.of(context).pop();
  }
}
