import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/habit.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import '../widgets/modal_page.dart';

/// Ouvre l'éditeur d'habitude, en création ou en modification.
Future<void> openHabitEditor(
  BuildContext context,
  WidgetRef ref, {
  Habit? habit,
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

    _titre = TextEditingController(text: habitude?.title ?? '')
      // Le bouton de validation s'active dès que l'intitulé n'est plus vide :
      // sur iOS on désactive l'action plutôt que d'afficher une erreur après coup.
      ..addListener(() => setState(() {}));
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

  /// L'action de validation n'est proposée que si le formulaire est complet.
  bool get _valide {
    if (_titre.text.trim().isEmpty) return false;
    if (_typePlanif == ScheduleKind.weekdays && _jours.isEmpty) return false;
    return true;
  }

  Future<void> _enregistrer() async {
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
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _enregistrement = false);
      // Débloquer le bouton ne suffit pas : sans message, l'utilisateur
      // rappuierait sans comprendre pourquoi rien ne se passe.
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
    final secondaire = CupertinoDynamicColor.resolve(
      AppTheme.secondaryLabel,
      context,
    );

    return AppFormPage(
      title: widget.habit == null ? 'Nouvelle habitude' : 'Modifier',
      actionLabel: widget.habit == null ? 'Créer' : 'OK',
      onAction: _valide && !_enregistrement ? _enregistrer : null,
      onDelete: widget.habit == null ? null : _confirmerSuppression,
      deleteLabel: 'Supprimer l\'habitude',
      children: [
        AppTextField(
          controller: _titre,
          placeholder: 'Ex. : lire 10 pages',
          autofocus: widget.habit == null,
        ),
        Gaps.h8,
        AppTextField(
          controller: _note,
          placeholder: 'Note (facultatif)',
          maxLines: 2,
        ),

        Gaps.h24,
        const FormLabel('Domaine'),
        Gaps.h8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final categorie in data.activeCategories)
              _CategoryPill(
                emoji: categorie.emoji,
                name: categorie.name,
                color: categorie.color,
                selected: _categorieId == categorie.id,
                onTap: () => setState(() => _categorieId = categorie.id),
              ),
          ],
        ),

        Gaps.h24,
        const FormLabel('Type'),
        Gaps.h8,
        AppSegmented<HabitPolarity>(
          value: _polarite,
          onChanged: (v) => setState(() => _polarite = v),
          children: const {
            HabitPolarity.positive: SegmentLabel('À faire'),
            HabitPolarity.negative: SegmentLabel('À éviter'),
          },
        ),
        Gaps.h8,
        _Hint(
          _polarite == HabitPolarity.negative
              ? 'La journée est réussie si tu ne craques pas.'
              : 'La journée est réussie si tu la fais.',
          color: secondaire,
        ),

        Gaps.h24,
        const FormLabel('Exigence'),
        Gaps.h8,
        AppSegmented<HabitDifficulty>(
          value: _difficulte,
          onChanged: (v) => setState(() => _difficulte = v),
          children: {
            for (final d in HabitDifficulty.values)
              d: SegmentLabel(d.label, detail: '+${d.xp} XP'),
          },
        ),

        Gaps.h24,
        const FormLabel('Pénalité si manquée'),
        Gaps.h8,
        AppSegmented<HabitPenalty>(
          value: _penalite,
          onChanged: (v) => setState(() => _penalite = v),
          children: {
            for (final p in HabitPenalty.values)
              p: SegmentLabel(
                p.label,
                detail: p == HabitPenalty.none ? null : '-${p.xp} XP',
              ),
          },
        ),
        Gaps.h8,
        _Hint(
          _penalite == HabitPenalty.none
              ? 'Aucune XP n\'est retirée si tu manques cette habitude.'
              : 'Manquer cette habitude te coûtera ${_penalite.xp} XP.',
          color: secondaire,
        ),

        Gaps.h24,
        const FormLabel('Rythme'),
        Gaps.h8,
        AppSegmented<ScheduleKind>(
          value: _typePlanif,
          onChanged: (v) => setState(() => _typePlanif = v),
          children: const {
            ScheduleKind.daily: SegmentLabel('Chaque jour'),
            ScheduleKind.weekdays: SegmentLabel('Jours choisis'),
            ScheduleKind.timesPerWeek: SegmentLabel('N× / sem.'),
          },
        ),
        if (_typePlanif == ScheduleKind.weekdays) ...[
          Gaps.h16,
          _WeekdayPicker(
            selected: _jours,
            onChanged: (jours) => setState(() => _jours = jours),
          ),
          if (_jours.isEmpty) ...[
            Gaps.h8,
            _Hint('Choisis au moins un jour.', color: AppTheme.missed),
          ],
        ],
        if (_typePlanif == ScheduleKind.timesPerWeek) ...[
          Gaps.h16,
          Row(
            children: [
              Expanded(
                child: CupertinoSlider(
                  value: _foisParSemaine.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  activeColor: AppTheme.seed,
                  onChanged: (v) => setState(() => _foisParSemaine = v.round()),
                ),
              ),
              SizedBox(
                width: 76,
                child: Text(
                  '$_foisParSemaine / sem.',
                  textAlign: TextAlign.end,
                  style: AppText.readout(
                    size: 15,
                    color: CupertinoDynamicColor.resolve(
                      AppTheme.label,
                      context,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Gaps.h8,
          _Hint(
            'La série se compte alors en semaines réussies, pas en jours.',
            color: secondaire,
          ),
        ],
      ],
    );
  }

  Future<void> _confirmerSuppression() async {
    final habitude = widget.habit!;
    final confirme = await confirmDestructive(
      context,
      title: 'Supprimer cette habitude ?',
      message:
          'Tous les pointages de « ${habitude.title} » seront effacés. '
          'L\'XP déjà gagnée reste acquise.',
    );

    if (!confirme || !mounted) return;
    await ref.read(appControllerProvider.notifier).deleteHabit(habitude.id);
    if (mounted) Navigator.of(context).pop();
  }
}

/// Explication discrète sous un contrôle.
class _Hint extends StatelessWidget {
  const _Hint(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: AppText.caption(color, size: 12)),
    );
  }
}

/// Capsule de sélection d'un domaine.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.emoji,
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texte = selected
        ? color
        : CupertinoDynamicColor.resolve(AppTheme.secondaryLabel, context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : CupertinoDynamicColor.resolve(AppTheme.field, context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.45)
                : CupertinoDynamicColor.resolve(AppTheme.separator, context),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            Gaps.w4,
            Text(
              name,
              style: TextStyle(
                fontFamily: 'CupertinoSystemText',
                fontSize: 14,
                letterSpacing: -0.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: texte,
              ),
            ),
          ],
        ),
      ),
    );
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var jour = 1; jour <= 7; jour++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final suivant = {...selected};
              if (!suivant.remove(jour)) suivant.add(jour);
              onChanged(suivant);
            },
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected.contains(jour)
                    ? AppTheme.seed
                    : CupertinoDynamicColor.resolve(AppTheme.field, context),
                border: Border.all(
                  color: CupertinoDynamicColor.resolve(
                    AppTheme.separator,
                    context,
                  ),
                  width: 0.5,
                ),
              ),
              child: Text(
                initiales[jour - 1],
                style: AppText.title(
                  selected.contains(jour)
                      ? CupertinoColors.white
                      : CupertinoDynamicColor.resolve(
                          AppTheme.secondaryLabel,
                          context,
                        ),
                  size: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
