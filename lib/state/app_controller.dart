import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/util/day.dart';
import '../data/repository.dart';
import '../data/seed.dart';
import '../domain/engine/streaks.dart';
import '../domain/engine/xp_rules.dart';
import '../domain/models/app_data.dart';
import '../domain/models/category.dart';
import '../domain/models/goal.dart';
import '../domain/models/habit.dart';
import '../domain/models/habit_log.dart';
import 'providers.dart';

/// Ce qu'un pointage a produit, pour pouvoir le retourner à l'interface.
class XpEvent {
  const XpEvent({
    required this.xpDelta,
    required this.categoryId,
    required this.leveledUp,
    required this.newLevel,
    this.label = '',
  });

  /// XP gagnée (positive) ou reprise (négative).
  final int xpDelta;
  final String categoryId;

  /// Vrai si l'opération a fait franchir un niveau de catégorie.
  final bool leveledUp;
  final int newLevel;
  final String label;
}

/// Le cerveau de l'application : détient l'état, applique les règles d'XP,
/// et persiste après chaque mutation.
class AppController extends AsyncNotifier<AppData> {
  static const _uuid = Uuid();

  late final LeveliaRepository _repository = ref.read(repositoryProvider);

  @override
  Future<AppData> build() => _repository.load();

  AppData get _data => state.requireValue;

  /// Applique une transformation puis persiste. Toute mutation passe par ici.
  Future<void> _mutate(AppData Function(AppData) transform) async {
    final suivant = transform(_data);
    state = AsyncData(suivant);
    await _repository.save(suivant);
  }

  // ---------------------------------------------------------------- Pointages

  /// Fait avancer une habitude d'un cran pour la journée [day].
  ///
  /// Le cycle est : non renseigné → réussi → manqué → non renseigné.
  /// L'XP est créditée à l'entrée dans « réussi » et reprise à la sortie, à
  /// hauteur exacte de ce qui avait été accordé.
  Future<XpEvent?> cycleHabit(Habit habit, DateTime day) async {
    final jour = dayOf(day);
    final existant = _data.logFor(habit.id, jour);

    if (existant == null) {
      return _markDone(habit, jour);
    }
    if (existant.done) {
      return _markMissed(habit, jour, existant);
    }
    return _clearLog(habit, jour);
  }

  /// Force une habitude à l'état « réussi » (utilisé par la case à cocher).
  Future<XpEvent?> setHabitDone(
    Habit habit,
    DateTime day, {
    required bool done,
  }) async {
    final jour = dayOf(day);
    final existant = _data.logFor(habit.id, jour);

    if (done) {
      if (existant != null && existant.done) return null;
      if (existant != null) await _clearLog(habit, jour);
      return _markDone(habit, jour);
    }

    if (existant == null) return null;
    if (existant.done) return _markMissed(habit, jour, existant);
    return null;
  }

  Future<XpEvent> _markDone(Habit habit, DateTime jour) async {
    final serieAvant = Streaks.streakBefore(_data, habit, jour);
    final gain = XpRules.awardFor(habit, streakBefore: serieAvant);

    final avant = _levelOfCategory(habit.categoryId);

    await _mutate((data) {
      final log = HabitLog(
        habitId: habit.id,
        day: jour,
        done: true,
        xpAwarded: gain,
        markedAt: DateTime.now(),
      );
      return _withLog(_addXp(data, habit.categoryId, gain), log);
    });

    final apres = _levelOfCategory(habit.categoryId);
    return XpEvent(
      xpDelta: gain,
      categoryId: habit.categoryId,
      leveledUp: apres > avant,
      newLevel: apres,
      label: habit.title,
    );
  }

  Future<XpEvent> _markMissed(
    Habit habit,
    DateTime jour,
    HabitLog existant,
  ) async {
    final repris = existant.xpAwarded;

    await _mutate((data) {
      final log = existant.copyWith(
        done: false,
        xpAwarded: 0,
        markedAt: DateTime.now(),
      );
      return _withLog(_addXp(data, habit.categoryId, -repris), log);
    });

    return XpEvent(
      xpDelta: -repris,
      categoryId: habit.categoryId,
      leveledUp: false,
      newLevel: _levelOfCategory(habit.categoryId),
      label: habit.title,
    );
  }

  Future<XpEvent?> _clearLog(Habit habit, DateTime jour) async {
    await _mutate((data) {
      final logs = Map<String, HabitLog>.from(data.logs)
        ..remove(HabitLog.logKey(habit.id, jour));
      return data.copyWith(logs: logs);
    });
    return null;
  }

  AppData _withLog(AppData data, HabitLog log) {
    final logs = Map<String, HabitLog>.from(data.logs)..[log.key] = log;
    return data.copyWith(logs: logs);
  }

  /// Ajoute (ou retire si négatif) de l'XP à une catégorie, sans jamais
  /// descendre sous zéro.
  AppData _addXp(AppData data, String categoryId, int delta) {
    final categories = [
      for (final c in data.categories)
        if (c.id == categoryId)
          c.copyWith(xp: (c.xp + delta).clamp(0, 1 << 30))
        else
          c,
    ];
    return data.copyWith(categories: categories);
  }

  int _levelOfCategory(String categoryId) {
    final categorie = _data.categoryById(categoryId);
    if (categorie == null) return 1;
    return categorie.levelInfo.level;
  }

  // ---------------------------------------------------------------- Habitudes

  Future<Habit> addHabit({
    required String title,
    required String categoryId,
    String note = '',
    HabitPolarity polarity = HabitPolarity.positive,
    HabitDifficulty difficulty = HabitDifficulty.normal,
    HabitSchedule schedule = const HabitSchedule.daily(),
  }) async {
    final habitude = Habit(
      id: _uuid.v4(),
      title: title.trim(),
      note: note.trim(),
      categoryId: categoryId,
      polarity: polarity,
      difficulty: difficulty,
      schedule: schedule,
      createdAt: today(),
      sortIndex: _data.habits.length,
    );
    await _mutate((data) => data.copyWith(habits: [...data.habits, habitude]));
    return habitude;
  }

  Future<void> updateHabit(Habit habit) async {
    await _mutate(
      (data) => data.copyWith(
        habits: [
          for (final h in data.habits)
            if (h.id == habit.id) habit else h,
        ],
      ),
    );
  }

  /// Archive une habitude : elle disparaît du quotidien mais son historique
  /// et l'XP déjà gagnée restent acquis.
  Future<void> archiveHabit(String habitId, {bool archived = true}) async {
    await _mutate(
      (data) => data.copyWith(
        habits: [
          for (final h in data.habits)
            if (h.id == habitId) h.copyWith(archived: archived) else h,
        ],
      ),
    );
  }

  /// Supprime définitivement une habitude et tous ses pointages.
  ///
  /// L'XP déjà attribuée n'est pas reprise : elle a été méritée.
  Future<void> deleteHabit(String habitId) async {
    await _mutate((data) {
      final logs = Map<String, HabitLog>.from(data.logs)
        ..removeWhere((_, log) => log.habitId == habitId);
      return data.copyWith(
        habits: data.habits.where((h) => h.id != habitId).toList(),
        logs: logs,
      );
    });
  }

  // --------------------------------------------------------------- Catégories

  Future<Category> addCategory({
    required String name,
    required String emoji,
    required int colorValue,
  }) async {
    final categorie = Category(
      id: _uuid.v4(),
      name: name.trim(),
      emoji: emoji,
      colorValue: colorValue,
      sortIndex: _data.categories.length,
    );
    await _mutate(
      (data) => data.copyWith(categories: [...data.categories, categorie]),
    );
    return categorie;
  }

  Future<void> updateCategory(Category category) async {
    await _mutate(
      (data) => data.copyWith(
        categories: [
          for (final c in data.categories)
            if (c.id == category.id) category else c,
        ],
      ),
    );
  }

  /// Supprime une catégorie ainsi que tout ce qu'elle contient.
  ///
  /// L'XP de la catégorie disparaît avec elle, ce qui fait baisser le niveau
  /// global : c'est volontaire, une catégorie supprimée n'a plus à compter.
  Future<void> deleteCategory(String categoryId) async {
    await _mutate((data) {
      final habitsSupprimees = data.habits
          .where((h) => h.categoryId == categoryId)
          .map((h) => h.id)
          .toSet();
      final logs = Map<String, HabitLog>.from(data.logs)
        ..removeWhere((_, log) => habitsSupprimees.contains(log.habitId));

      return data.copyWith(
        categories: data.categories.where((c) => c.id != categoryId).toList(),
        habits: data.habits.where((h) => h.categoryId != categoryId).toList(),
        goals: data.goals.where((g) => g.categoryId != categoryId).toList(),
        logs: logs,
      );
    });
  }

  // --------------------------------------------------------------- Objectifs

  Future<Goal> addGoal({
    required String title,
    required String categoryId,
    String description = '',
    DateTime? targetDate,
    List<String> milestoneTitles = const [],
  }) async {
    final objectif = Goal(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      categoryId: categoryId,
      createdAt: today(),
      targetDate: targetDate == null ? null : dayOf(targetDate),
      milestones: [
        for (final t in milestoneTitles)
          if (t.trim().isNotEmpty) Milestone(id: _uuid.v4(), title: t.trim()),
      ],
    );
    await _mutate((data) => data.copyWith(goals: [...data.goals, objectif]));
    return objectif;
  }

  Future<void> updateGoal(Goal goal) async {
    await _mutate(
      (data) => data.copyWith(
        goals: [
          for (final g in data.goals)
            if (g.id == goal.id) goal else g,
        ],
      ),
    );
  }

  Future<void> deleteGoal(String goalId) async {
    await _mutate(
      (data) =>
          data.copyWith(goals: data.goals.where((g) => g.id != goalId).toList()),
    );
  }

  /// Coche ou décoche une étape, en créditant ou reprenant son XP.
  Future<XpEvent?> toggleMilestone(String goalId, String milestoneId) async {
    final objectif = _data.goalById(goalId);
    if (objectif == null) return null;

    final etape = objectif.milestones.firstWhere(
      (m) => m.id == milestoneId,
      orElse: () => const Milestone(id: '', title: ''),
    );
    if (etape.id.isEmpty) return null;

    final desormaisFaite = !etape.done;
    final delta = desormaisFaite ? Milestone.xpReward : -Milestone.xpReward;
    final avant = _levelOfCategory(objectif.categoryId);

    await _mutate((data) {
      final maj = objectif.copyWith(
        milestones: [
          for (final m in objectif.milestones)
            if (m.id == milestoneId)
              m.copyWith(
                done: desormaisFaite,
                completedAt: desormaisFaite ? DateTime.now() : null,
              )
            else
              m,
        ],
      );
      final avecObjectif = data.copyWith(
        goals: [
          for (final g in data.goals)
            if (g.id == goalId) maj else g,
        ],
      );
      return _addXp(avecObjectif, objectif.categoryId, delta);
    });

    final apres = _levelOfCategory(objectif.categoryId);
    return XpEvent(
      xpDelta: delta,
      categoryId: objectif.categoryId,
      leveledUp: apres > avant,
      newLevel: apres,
      label: etape.title,
    );
  }

  /// Marque un objectif comme atteint (ou le rouvre), avec la prime associée.
  Future<XpEvent?> toggleGoalCompletion(String goalId) async {
    final objectif = _data.goalById(goalId);
    if (objectif == null) return null;

    final desormaisFini = !objectif.isCompleted;
    final delta = desormaisFini ? objectif.xpReward : -objectif.xpReward;
    final avant = _levelOfCategory(objectif.categoryId);

    await _mutate((data) {
      final maj = desormaisFini
          ? objectif.copyWith(completedAt: DateTime.now())
          : objectif.copyWith(clearCompletedAt: true);
      final avecObjectif = data.copyWith(
        goals: [
          for (final g in data.goals)
            if (g.id == goalId) maj else g,
        ],
      );
      return _addXp(avecObjectif, objectif.categoryId, delta);
    });

    final apres = _levelOfCategory(objectif.categoryId);
    return XpEvent(
      xpDelta: delta,
      categoryId: objectif.categoryId,
      leveledUp: apres > avant,
      newLevel: apres,
      label: objectif.title,
    );
  }

  // ------------------------------------------------------------------ Profil

  Future<void> renameProfile(String name) async {
    final propre = name.trim();
    if (propre.isEmpty) return;
    await _mutate((data) => data.copyWith(profileName: propre));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _mutate((data) => data.copyWith(themeMode: mode));
  }

  /// Sérialise tout l'état, pour une sauvegarde manuelle.
  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_data.toJson());

  /// Remplace l'état par le contenu d'un export.
  ///
  /// Lève une [FormatException] si le contenu est illisible ; l'état en place
  /// n'est alors pas touché.
  Future<void> importJson(String raw) async {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final importe = AppData.fromJson(json);
    state = AsyncData(importe);
    await _repository.save(importe);
  }

  /// Repart de zéro avec les catégories et exemples d'origine.
  Future<void> resetAll() async {
    await _mutate((_) => buildSeedData());
  }
}
