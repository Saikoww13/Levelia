import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/habit.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/sheet.dart';

/// Ouvre l'éditeur d'habitude, en création ou en modification.
Future<void> openHabitEditor(
  BuildContext context,
  WidgetRef ref, {
  Habit? habit,
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
    title: habit == null ? 'Nouvelle habitude' : 'Modifier l\'habitude',
    builder: (_) => _HabitEditor(habit: habit),
  );
}

class _HabitEditor extends ConsumerStatefulWidget {
  const _HabitEditor({this.habit});

  final Habit? habit;

  @override
  ConsumerState<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends ConsumerState<_HabitEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titre;
  late final TextEditingController _note;

  late String _categorieId;
  late HabitPolarity _polarite;
  late HabitDifficulty _difficulte;
  late HabitPenalty _penalite;
  late ScheduleKind _typePlanif;
  late Set<int> _jours;
  late int _foisParSemaine;

  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    final habitude = widget.habit;
    final data = ref.read(appDataProvider);

    _titre = TextEditingController(text: habitude?.title ?? '');
    _note = TextEditingController(text: habitude?.note ?? '');
    _categorieId = habitude?.categoryId ?? data.activeCategories.first.id;
    _polarite = habitude?.polarity ?? HabitPolarity.positive;
    _difficulte = habitude?.difficulty ?? HabitDifficulty.normal;
    _penalite = habitude?.penalty ?? HabitPenalty.none;

    final planif = habitude?.schedule ?? const HabitSchedule.daily();
    _typePlanif = planif.kind;
    _jours = {...planif.weekdays};
    _foisParSemaine = planif.timesPerWeek <= 0 ? 3 : planif.timesPerWeek;

    if (_typePlanif == ScheduleKind.weekdays && _jours.isEmpty) {
      _jours = {1, 2, 3, 4, 5};
    }
  }

  @override
  void dispose() {
    _titre.dispose();
    _note.dispose();
    super.dispose();
  }

  HabitSchedule get _planification => switch (_typePlanif) {
    ScheduleKind.daily => const HabitSchedule.daily(),
    ScheduleKind.weekdays => HabitSchedule.onWeekdays(_jours),
    ScheduleKind.timesPerWeek => HabitSchedule.timesAWeek(_foisParSemaine),
  };

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_typePlanif == ScheduleKind.weekdays && _jours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis au moins un jour.')),
      );
      return;
    }

    setState(() => _enregistrement = true);
    try {
      final controleur = ref.read(appControllerProvider.notifier);
      final existante = widget.habit;

      if (existante == null) {
        await controleur.addHabit(
          title: _titre.text,
          categoryId: _categorieId,
          note: _note.text,
          polarity: _polarite,
          difficulty: _difficulte,
          penalty: _penalite,
          schedule: _planification,
        );
      } else {
        await controleur.updateHabit(
          existante.copyWith(
            title: _titre.text.trim(),
            note: _note.text.trim(),
            categoryId: _categorieId,
            polarity: _polarite,
            difficulty: _difficulte,
            penalty: _penalite,
            schedule: _planification,
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
            autofocus: widget.habit == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Intitulé',
              hintText: 'Ex. : lire 10 pages',
            ),
            validator: (valeur) => (valeur ?? '').trim().isEmpty
                ? 'Donne un intitulé à ton habitude'
                : null,
          ),
          Gaps.h12,
          TextFormField(
            controller: _note,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (facultatif)',
              hintText: 'Une précision qui t\'aide à t\'y tenir',
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
          const FormLabel('Type'),
          Gaps.h8,
          SegmentedButton<HabitPolarity>(
            segments: const [
              ButtonSegment(
                value: HabitPolarity.positive,
                icon: Icon(Icons.add_task),
                label: Text('À faire'),
              ),
              ButtonSegment(
                value: HabitPolarity.negative,
                icon: Icon(Icons.block),
                label: Text('À éviter'),
              ),
            ],
            selected: {_polarite},
            onSelectionChanged: (choix) =>
                setState(() => _polarite = choix.first),
          ),
          Gaps.h8,
          Text(
            _polarite == HabitPolarity.negative
                ? 'La journée est réussie si tu ne craques pas.'
                : 'La journée est réussie si tu la fais.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          Gaps.h24,
          const FormLabel('Exigence'),
          Gaps.h8,
          SegmentedButton<HabitDifficulty>(
            segments: [
              for (final d in HabitDifficulty.values)
                ButtonSegment(
                  value: d,
                  label: Text('${d.label}\n+${d.xp} XP', textAlign: TextAlign.center),
                ),
            ],
            selected: {_difficulte},
            onSelectionChanged: (choix) =>
                setState(() => _difficulte = choix.first),
          ),

          Gaps.h24,
          const FormLabel('Pénalité si manquée'),
          Gaps.h8,
          SegmentedButton<HabitPenalty>(
            segments: [
              for (final p in HabitPenalty.values)
                ButtonSegment(
                  value: p,
                  label: Text(
                    p == HabitPenalty.none ? p.label : '${p.label}\n-${p.xp} XP',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
            selected: {_penalite},
            onSelectionChanged: (choix) =>
                setState(() => _penalite = choix.first),
          ),
          Gaps.h8,
          Text(
            _penalite == HabitPenalty.none
                ? 'Aucune XP n\'est retirée si tu manques cette habitude.'
                : 'Manquer cette habitude te coûtera ${_penalite.xp} XP.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          Gaps.h24,
          const FormLabel('Rythme'),
          Gaps.h8,
          SegmentedButton<ScheduleKind>(
            segments: const [
              ButtonSegment(
                value: ScheduleKind.daily,
                label: Text('Chaque jour'),
              ),
              ButtonSegment(
                value: ScheduleKind.weekdays,
                label: Text('Jours choisis'),
              ),
              ButtonSegment(
                value: ScheduleKind.timesPerWeek,
                label: Text('N× / semaine'),
              ),
            ],
            selected: {_typePlanif},
            onSelectionChanged: (choix) =>
                setState(() => _typePlanif = choix.first),
          ),
          if (_typePlanif == ScheduleKind.weekdays) ...[
            Gaps.h12,
            _WeekdayPicker(
              selected: _jours,
              onChanged: (jours) => setState(() => _jours = jours),
            ),
          ],
          if (_typePlanif == ScheduleKind.timesPerWeek) ...[
            Gaps.h12,
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _foisParSemaine.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '$_foisParSemaine',
                    onChanged: (v) =>
                        setState(() => _foisParSemaine = v.round()),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    '$_foisParSemaine fois',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            Text(
              'La série se compte alors en semaines réussies, pas en jours.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          Gaps.h32,
          Row(
            children: [
              if (widget.habit != null)
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
                child: Text(
                  widget.habit == null ? 'Créer' : 'Enregistrer',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerSuppression() async {
    final habitude = widget.habit!;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: const Text('Supprimer cette habitude ?'),
        content: Text(
          'Tous les pointages de « ${habitude.title} » seront effacés. '
          'L\'XP déjà gagnée reste acquise.',
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
    await ref.read(appControllerProvider.notifier).deleteHabit(habitude.id);
    if (mounted) Navigator.of(context).pop();
  }
}

/// Sélecteur des jours de la semaine, en pastilles L M M J V S D.
class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    const initiales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var jour = 1; jour <= 7; jour++)
          GestureDetector(
            onTap: () {
              final suivant = {...selected};
              if (!suivant.remove(jour)) suivant.add(jour);
              onChanged(suivant);
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected.contains(jour)
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                initiales[jour - 1],
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected.contains(jour)
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

