import 'package:flutter/material.dart';

import '../../core/util/day.dart';

/// Le pointage d'une habitude pour une journée donnée.
///
/// L'absence de log signifie « pas encore renseigné ». Un log avec [done] à
/// `false` est un échec explicitement déclaré (raté, ou craqué pour une
/// habitude à éviter).
@immutable
class HabitLog {
  const HabitLog({
    required this.habitId,
    required this.day,
    required this.done,
    this.xpAwarded = 0,
    this.markedAt,
  });

  final String habitId;

  /// Journée concernée, normalisée à minuit.
  final DateTime day;

  final bool done;

  /// XP réellement créditée lors du pointage.
  ///
  /// Mémorisée pour pouvoir la retirer à l'identique si l'on décoche, sans
  /// avoir à recalculer un bonus de série qui a pu changer entre-temps.
  final int xpAwarded;

  final DateTime? markedAt;

  /// Identité d'un pointage : une habitude, une journée.
  String get key => logKey(habitId, day);

  static String logKey(String habitId, DateTime day) =>
      '$habitId@${dayKey(day)}';

  HabitLog copyWith({bool? done, int? xpAwarded, DateTime? markedAt}) {
    return HabitLog(
      habitId: habitId,
      day: day,
      done: done ?? this.done,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      markedAt: markedAt ?? this.markedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'habitId': habitId,
    'day': dayKey(day),
    'done': done,
    'xpAwarded': xpAwarded,
    'markedAt': markedAt?.toIso8601String(),
  };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
    habitId: json['habitId'] as String,
    day: parseDayKey(json['day'] as String),
    done: json['done'] as bool? ?? false,
    xpAwarded: json['xpAwarded'] as int? ?? 0,
    markedAt: DateTime.tryParse(json['markedAt'] as String? ?? ''),
  );
}
