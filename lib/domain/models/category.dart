import 'package:flutter/material.dart';

import '../engine/leveling.dart';

/// Un domaine de vie que l'on fait progresser : Sport, Esprit, Travail…
///
/// Chaque catégorie possède sa propre cagnotte d'XP, donc son propre niveau.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    this.xp = 0,
    this.archived = false,
    this.sortIndex = 0,
  });

  final String id;
  final String name;

  /// Emoji affiché en pastille. Une seule « lettre » visuelle.
  final String emoji;

  /// Couleur d'accent, stockée en ARGB pour rester sérialisable.
  final int colorValue;

  /// XP cumulée dans cette catégorie. Détermine son niveau.
  final int xp;

  final bool archived;
  final int sortIndex;

  Color get color => Color(colorValue);

  /// Progression de ce domaine, déduite de son XP.
  LevelInfo get levelInfo => Leveling.describe(xp);

  Category copyWith({
    String? name,
    String? emoji,
    int? colorValue,
    int? xp,
    bool? archived,
    int? sortIndex,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      xp: xp ?? this.xp,
      archived: archived ?? this.archived,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'colorValue': colorValue,
    'xp': xp,
    'archived': archived,
    'sortIndex': sortIndex,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '⭐',
    colorValue: json['colorValue'] as int? ?? 0xFF6C63FF,
    xp: json['xp'] as int? ?? 0,
    archived: json['archived'] as bool? ?? false,
    sortIndex: json['sortIndex'] as int? ?? 0,
  );
}
