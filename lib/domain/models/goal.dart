import 'package:flutter/foundation.dart' show immutable;

import '../../core/util/day.dart';

/// Une étape intermédiaire d'un objectif.
@immutable
class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    this.done = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final bool done;
  final DateTime? completedAt;

  /// XP accordée pour une étape franchie.
  static const int xpReward = 20;

  Milestone copyWith({String? title, bool? done, DateTime? completedAt}) {
    return Milestone(
      id: id,
      title: title ?? this.title,
      done: done ?? this.done,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    id: json['id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool? ?? false,
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
  );
}

/// Un objectif : une destination, découpée en étapes, rattachée à une catégorie.
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.createdAt,
    this.description = '',
    this.targetDate,
    this.milestones = const [],
    this.completedAt,
    this.xpReward = defaultXpReward,
  });

  /// XP accordée à l'achèvement d'un objectif, en plus de celle des étapes.
  static const int defaultXpReward = 100;

  final String id;
  final String title;
  final String description;
  final String categoryId;
  final DateTime createdAt;

  /// Échéance visée, facultative.
  final DateTime? targetDate;

  final List<Milestone> milestones;
  final DateTime? completedAt;
  final int xpReward;

  bool get isCompleted => completedAt != null;

  int get milestonesDone => milestones.where((m) => m.done).length;

  /// Avancement entre 0 et 1, déduit des étapes franchies.
  ///
  /// Sans étape, un objectif est à 0 % tant qu'il n'est pas marqué terminé.
  double get progress {
    if (isCompleted) return 1;
    if (milestones.isEmpty) return 0;
    return milestonesDone / milestones.length;
  }

  /// Jours restants avant l'échéance. `null` si aucune échéance.
  int? get daysLeft {
    final cible = targetDate;
    if (cible == null || isCompleted) return null;
    return daysBetween(today(), cible);
  }

  /// Vrai si l'échéance est dépassée et l'objectif toujours ouvert.
  bool get isOverdue {
    final restants = daysLeft;
    return restants != null && restants < 0;
  }

  Goal copyWith({
    String? title,
    String? description,
    String? categoryId,
    DateTime? targetDate,
    bool clearTargetDate = false,
    List<Milestone>? milestones,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? xpReward,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      milestones: milestones ?? this.milestones,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      xpReward: xpReward ?? this.xpReward,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
    'targetDate': targetDate == null ? null : dayKey(targetDate!),
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'completedAt': completedAt?.toIso8601String(),
    'xpReward': xpReward,
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    categoryId: json['categoryId'] as String,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    targetDate: json['targetDate'] == null
        ? null
        : parseDayKey(json['targetDate'] as String),
    milestones: ((json['milestones'] as List?) ?? const [])
        .map((e) => Milestone.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    xpReward: json['xpReward'] as int? ?? defaultXpReward,
  );
}
