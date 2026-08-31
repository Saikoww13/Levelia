import 'package:flutter/foundation.dart' show immutable;

/// Une récompense que l'on s'accorde en atteignant un niveau donné.
///
/// L'application ne décide jamais de la récompense : c'est l'utilisateur qui
/// écrit la sienne (« s'acheter ce jeu », « une soirée sans écran »). Elle est
/// posée sur un nœud de l'arbre de compétences, donc sur un couple
/// branche + niveau.
@immutable
class Reward {
  const Reward({
    required this.id,
    required this.level,
    required this.title,
    this.categoryId,
    this.claimedAt,
  });

  final String id;

  /// Niveau qui débloque la récompense. Toujours >= 2 : le niveau 1 est le
  /// point de départ, il ne se franchit pas.
  final int level;

  /// Texte libre, écrit par l'utilisateur.
  final String title;

  /// Domaine porteur, ou `null` pour la branche globale.
  ///
  /// Ce `null` est significatif et non un simple défaut : il distingue la
  /// branche du tronc de celles des domaines.
  final String? categoryId;

  /// Date à laquelle la récompense a été savourée, ou `null` si elle attend.
  final DateTime? claimedAt;

  /// Vrai pour une récompense de la branche globale.
  bool get isGlobal => categoryId == null;

  /// Vrai une fois la récompense consommée.
  bool get claimed => claimedAt != null;

  /// Vrai si le niveau [niveauAtteint] de la branche débloque la récompense.
  bool unlockedAt(int niveauAtteint) => niveauAtteint >= level;

  Reward copyWith({
    int? level,
    String? title,
    DateTime? claimedAt,
    bool clearClaimedAt = false,
  }) {
    return Reward(
      id: id,
      level: level ?? this.level,
      title: title ?? this.title,
      categoryId: categoryId,
      claimedAt: clearClaimedAt ? null : (claimedAt ?? this.claimedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'title': title,
    'categoryId': categoryId,
    'claimedAt': claimedAt?.toIso8601String(),
  };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    id: json['id'] as String,
    level: json['level'] as int? ?? 2,
    title: json['title'] as String? ?? '',
    categoryId: json['categoryId'] as String?,
    claimedAt: DateTime.tryParse(json['claimedAt'] as String? ?? ''),
  );
}
