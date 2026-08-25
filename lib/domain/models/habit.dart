import 'package:flutter/material.dart';

/// Sens d'une habitude.
enum HabitPolarity {
  /// À faire : cocher la journée rapporte de l'XP.
  positive,

  /// À éviter : la journée est réussie tant qu'on n'a pas craqué.
  negative;

  String get label => switch (this) {
    HabitPolarity.positive => 'À faire',
    HabitPolarity.negative => 'À éviter',
  };

  String get storageKey => name;

  static HabitPolarity fromKey(String? key) => HabitPolarity.values.firstWhere(
    (p) => p.name == key,
    orElse: () => HabitPolarity.positive,
  );
}

/// Exigence d'une habitude, qui détermine l'XP rapportée.
enum HabitDifficulty {
  easy(10, 'Facile'),
  normal(15, 'Normale'),
  hard(25, 'Exigeante');

  const HabitDifficulty(this.xp, this.label);

  /// XP de base accordée pour une journée réussie.
  final int xp;
  final String label;

  static HabitDifficulty fromKey(String? key) =>
      HabitDifficulty.values.firstWhere(
        (d) => d.name == key,
        orElse: () => HabitDifficulty.normal,
      );
}

/// Pénalité d'XP appliquée quand une habitude est marquée manquée.
enum HabitPenalty {
  none(0, 'Aucune'),
  light(10, 'Légère'),
  moderate(15, 'Modérée'),
  severe(25, 'Sévère');

  const HabitPenalty(this.xp, this.label);

  /// XP retirée quand la journée est marquée manquée. Zéro pour [none].
  final int xp;
  final String label;

  static HabitPenalty fromKey(String? key) => HabitPenalty.values.firstWhere(
    (p) => p.name == key,
    orElse: () => HabitPenalty.none,
  );
}

/// Manière dont une habitude est planifiée dans la semaine.
enum ScheduleKind {
  /// Attendue tous les jours.
  daily,

  /// Attendue certains jours de la semaine seulement.
  weekdays,

  /// Attendue N fois par semaine, peu importe lesquels.
  timesPerWeek;

  static ScheduleKind fromKey(String? key) => ScheduleKind.values.firstWhere(
    (k) => k.name == key,
    orElse: () => ScheduleKind.daily,
  );
}

/// Planification d'une habitude.
@immutable
class HabitSchedule {
  const HabitSchedule({
    required this.kind,
    this.weekdays = const {},
    this.timesPerWeek = 3,
  });

  const HabitSchedule.daily() : kind = ScheduleKind.daily, weekdays = const {}, timesPerWeek = 7;

  /// [days] utilise la convention de [DateTime.weekday] : 1 = lundi … 7 = dimanche.
  const HabitSchedule.onWeekdays(Set<int> days)
    : kind = ScheduleKind.weekdays,
      weekdays = days,
      timesPerWeek = 0;

  const HabitSchedule.timesAWeek(int times)
    : kind = ScheduleKind.timesPerWeek,
      weekdays = const {},
      timesPerWeek = times;

  final ScheduleKind kind;

  /// Jours attendus, convention [DateTime.weekday] (1 = lundi … 7 = dimanche).
  final Set<int> weekdays;

  /// Nombre de réussites visées par semaine, pour [ScheduleKind.timesPerWeek].
  final int timesPerWeek;

  /// Vrai si l'habitude est attendue ce jour-là.
  ///
  /// Pour une planification « N fois par semaine » aucun jour n'est imposé :
  /// tous les jours sont donc proposés, et c'est le total hebdomadaire qui fait foi.
  bool isDueOn(DateTime date) => switch (kind) {
    ScheduleKind.daily => true,
    ScheduleKind.weekdays => weekdays.contains(date.weekday),
    ScheduleKind.timesPerWeek => true,
  };

  /// Nombre de journées attendues sur une semaine complète.
  int get expectedPerWeek => switch (kind) {
    ScheduleKind.daily => 7,
    ScheduleKind.weekdays => weekdays.length,
    ScheduleKind.timesPerWeek => timesPerWeek,
  };

  /// Vrai si rater un jour donné doit casser la série.
  ///
  /// Une habitude « N fois par semaine » ne se juge pas au jour le jour :
  /// sa série est calculée à la semaine.
  bool get isDayStrict => kind != ScheduleKind.timesPerWeek;

  String get label => switch (kind) {
    ScheduleKind.daily => 'Tous les jours',
    ScheduleKind.weekdays => _weekdaysLabel(),
    ScheduleKind.timesPerWeek => '$timesPerWeek× par semaine',
  };

  String _weekdaysLabel() {
    if (weekdays.isEmpty) return 'Aucun jour';
    if (weekdays.length == 7) return 'Tous les jours';
    const noms = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final tries = weekdays.toList()..sort();
    return tries.map((j) => noms[j - 1]).join(', ');
  }

  HabitSchedule copyWith({
    ScheduleKind? kind,
    Set<int>? weekdays,
    int? timesPerWeek,
  }) {
    return HabitSchedule(
      kind: kind ?? this.kind,
      weekdays: weekdays ?? this.weekdays,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'weekdays': weekdays.toList()..sort(),
    'timesPerWeek': timesPerWeek,
  };

  factory HabitSchedule.fromJson(Map<String, dynamic> json) => HabitSchedule(
    kind: ScheduleKind.fromKey(json['kind'] as String?),
    weekdays: ((json['weekdays'] as List?) ?? const [])
        .map((e) => e as int)
        .toSet(),
    timesPerWeek: json['timesPerWeek'] as int? ?? 3,
  );
}

/// Une habitude à suivre jour après jour.
@immutable
class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.createdAt,
    this.note = '',
    this.polarity = HabitPolarity.positive,
    this.difficulty = HabitDifficulty.normal,
    this.penalty = HabitPenalty.none,
    this.schedule = const HabitSchedule.daily(),
    this.archived = false,
    this.sortIndex = 0,
  });

  final String id;
  final String title;
  final String note;
  final String categoryId;
  final HabitPolarity polarity;
  final HabitDifficulty difficulty;
  final HabitPenalty penalty;
  final HabitSchedule schedule;
  final DateTime createdAt;
  final bool archived;
  final int sortIndex;

  bool get isNegative => polarity == HabitPolarity.negative;

  /// Verbe d'action affiché sur la case à cocher du jour.
  String get doneLabel => isNegative ? 'Tenu' : 'Fait';

  Habit copyWith({
    String? title,
    String? note,
    String? categoryId,
    HabitPolarity? polarity,
    HabitDifficulty? difficulty,
    HabitPenalty? penalty,
    HabitSchedule? schedule,
    bool? archived,
    int? sortIndex,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      polarity: polarity ?? this.polarity,
      difficulty: difficulty ?? this.difficulty,
      penalty: penalty ?? this.penalty,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt,
      archived: archived ?? this.archived,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'categoryId': categoryId,
    'polarity': polarity.name,
    'difficulty': difficulty.name,
    'penalty': penalty.name,
    'schedule': schedule.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'archived': archived,
    'sortIndex': sortIndex,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String,
    note: json['note'] as String? ?? '',
    categoryId: json['categoryId'] as String,
    polarity: HabitPolarity.fromKey(json['polarity'] as String?),
    difficulty: HabitDifficulty.fromKey(json['difficulty'] as String?),
    penalty: HabitPenalty.fromKey(json['penalty'] as String?),
    schedule: HabitSchedule.fromJson(
      (json['schedule'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    archived: json['archived'] as bool? ?? false,
    sortIndex: json['sortIndex'] as int? ?? 0,
  );
}
