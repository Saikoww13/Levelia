import 'package:flutter/foundation.dart' show immutable;

import '../engine/leveling.dart';
import 'category.dart';
import 'goal.dart';
import 'habit.dart';
import 'habit_log.dart';
import 'reward.dart';

/// Préférence d'apparence de l'application.
///
/// Enum maison plutôt que le `ThemeMode` de Material : le domaine ne doit
/// dépendre d'aucune bibliothèque d'interface. Les noms sont conservés à
/// l'identique pour que les sauvegardes existantes se relisent sans migration.
enum AppearanceMode {
  /// Suit le réglage du système.
  system,
  light,
  dark;

  String get label => switch (this) {
    AppearanceMode.system => 'Auto',
    AppearanceMode.light => 'Clair',
    AppearanceMode.dark => 'Sombre',
  };

  static AppearanceMode fromKey(String? key) => AppearanceMode.values
      .firstWhere((m) => m.name == key, orElse: () => AppearanceMode.system);
}

/// L'intégralité des données de l'utilisateur, en un seul objet immuable.
///
/// Tout passe par ici : c'est ce document qui est sérialisé en JSON pour le
/// stockage local, et qui servira de charge utile lors d'une future synchro.
@immutable
class AppData {
  const AppData({
    this.schemaVersion = currentSchemaVersion,
    this.profileName = 'Aventurier',
    this.themeMode = AppearanceMode.system,
    this.onboardingSeenAt,
    this.categories = const [],
    this.habits = const [],
    this.logs = const {},
    this.goals = const [],
    this.rewards = const [],
    this.updatedAt,
  });

  /// Version du format. À incrémenter en cas de changement cassant, pour
  /// permettre une migration à la lecture.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String profileName;

  /// Préférence d'apparence, conservée avec les données.
  final AppearanceMode themeMode;

  /// Date à laquelle l'introduction a été parcourue, ou `null` si elle ne l'a
  /// jamais été.
  ///
  /// C'est ce champ qui décide si l'application s'ouvre sur l'introduction. Le
  /// remettre à `null` la rejoue — c'est ce que fait « Revoir l'introduction ».
  final DateTime? onboardingSeenAt;

  /// Vrai tant que l'introduction n'a pas été parcourue.
  bool get needsOnboarding => onboardingSeenAt == null;

  final List<Category> categories;
  final List<Habit> habits;

  /// Pointages indexés par [HabitLog.key] (`habitId@yyyy-MM-dd`).
  final Map<String, HabitLog> logs;

  final List<Goal> goals;

  /// Récompenses posées sur les paliers de l'arbre de compétences.
  final List<Reward> rewards;

  final DateTime? updatedAt;

  /// Récompenses d'une branche, triées par palier.
  ///
  /// [categoryId] vaut `null` pour la branche globale — ce n'est pas
  /// « toutes les branches » mais bien le tronc.
  List<Reward> rewardsFor(String? categoryId) =>
      rewards.where((r) => r.categoryId == categoryId).toList()
        ..sort((a, b) => a.level.compareTo(b.level));

  /// Niveau atteint sur une branche, le tronc pour `null`.
  int levelOfBranch(String? categoryId) => categoryId == null
      ? globalLevel.level
      : (categoryById(categoryId)?.levelInfo.level ?? 1);

  /// Récompenses débloquées mais pas encore savourées, toutes branches
  /// confondues. C'est ce qui mérite une pastille dans l'interface.
  List<Reward> get rewardsWaiting =>
      rewards
          .where((r) => !r.claimed && r.unlockedAt(levelOfBranch(r.categoryId)))
          .toList()
        ..sort((a, b) => a.level.compareTo(b.level));

  /// XP totale : la somme des cagnottes de chaque catégorie.
  int get totalXp => categories.fold(0, (somme, c) => somme + c.xp);

  /// Progression globale, tous domaines confondus.
  LevelInfo get globalLevel => Leveling.describe(totalXp);

  List<Category> get activeCategories =>
      categories.where((c) => !c.archived).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  List<Habit> get activeHabits =>
      habits.where((h) => !h.archived).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

  List<Goal> get openGoals => goals.where((g) => !g.isCompleted).toList();

  List<Goal> get completedGoals => goals.where((g) => g.isCompleted).toList();

  Category? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Habit? habitById(String id) {
    for (final h in habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  Goal? goalById(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Le pointage d'une habitude pour une journée, s'il existe.
  HabitLog? logFor(String habitId, DateTime day) =>
      logs[HabitLog.logKey(habitId, day)];

  /// Les habitudes rattachées à une catégorie.
  List<Habit> habitsOf(String categoryId) =>
      activeHabits.where((h) => h.categoryId == categoryId).toList();

  /// Les objectifs rattachés à une catégorie.
  List<Goal> goalsOf(String categoryId) =>
      goals.where((g) => g.categoryId == categoryId).toList();

  AppData copyWith({
    String? profileName,
    AppearanceMode? themeMode,
    DateTime? onboardingSeenAt,
    bool clearOnboardingSeenAt = false,
    List<Category>? categories,
    List<Habit>? habits,
    Map<String, HabitLog>? logs,
    List<Goal>? goals,
    List<Reward>? rewards,
    DateTime? updatedAt,
  }) {
    return AppData(
      schemaVersion: schemaVersion,
      profileName: profileName ?? this.profileName,
      themeMode: themeMode ?? this.themeMode,
      onboardingSeenAt: clearOnboardingSeenAt
          ? null
          : (onboardingSeenAt ?? this.onboardingSeenAt),
      categories: categories ?? this.categories,
      habits: habits ?? this.habits,
      logs: logs ?? this.logs,
      goals: goals ?? this.goals,
      rewards: rewards ?? this.rewards,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'profileName': profileName,
    'themeMode': themeMode.name,
    'onboardingSeenAt': onboardingSeenAt?.toIso8601String(),
    'categories': categories.map((c) => c.toJson()).toList(),
    'habits': habits.map((h) => h.toJson()).toList(),
    'logs': logs.values.map((l) => l.toJson()).toList(),
    'goals': goals.map((g) => g.toJson()).toList(),
    'rewards': rewards.map((r) => r.toJson()).toList(),
    'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
  };

  factory AppData.fromJson(Map<String, dynamic> json) {
    final logs = <String, HabitLog>{};
    for (final brut in (json['logs'] as List?) ?? const []) {
      final log = HabitLog.fromJson((brut as Map).cast<String, dynamic>());
      logs[log.key] = log;
    }

    return AppData(
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      profileName: json['profileName'] as String? ?? 'Aventurier',
      themeMode: AppearanceMode.fromKey(json['themeMode'] as String?),
      onboardingSeenAt: DateTime.tryParse(
        json['onboardingSeenAt'] as String? ?? '',
      ),
      categories: ((json['categories'] as List?) ?? const [])
          .map((e) => Category.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      habits: ((json['habits'] as List?) ?? const [])
          .map((e) => Habit.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      logs: logs,
      goals: ((json['goals'] as List?) ?? const [])
          .map((e) => Goal.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      // Ajout tardif : une sauvegarde antérieure n'a pas cette clé et se
      // relit donc avec un arbre sans récompense, ce qui est correct.
      rewards: ((json['rewards'] as List?) ?? const [])
          .map((e) => Reward.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
