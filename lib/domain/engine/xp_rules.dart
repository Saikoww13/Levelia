import 'dart:math' as math;

import '../models/habit.dart';

/// Barème d'XP de l'application, rassemblé en un seul endroit pour rester réglable.
class XpRules {
  const XpRules._();

  /// Bonus d'XP accordé par jour de série déjà accumulé.
  static const int streakBonusPerDay = 2;

  /// Plafond du bonus de série, pour qu'une longue série ne rende pas
  /// les nouvelles habitudes insignifiantes.
  static const int maxStreakBonus = 20;

  /// XP accordée pour une journée réussie.
  ///
  /// [streakBefore] est la longueur de la série *avant* ce pointage : c'est
  /// elle qui alimente le bonus, pour que le tout premier jour rapporte la
  /// valeur de base.
  static int awardFor(Habit habit, {required int streakBefore}) {
    final bonus = math.min(
      math.max(0, streakBefore) * streakBonusPerDay,
      maxStreakBonus,
    );
    return habit.difficulty.xp + bonus;
  }

  /// Décomposition lisible d'un gain, pour l'afficher à l'utilisateur.
  static ({int base, int bonus}) breakdown(
    Habit habit, {
    required int streakBefore,
  }) {
    final total = awardFor(habit, streakBefore: streakBefore);
    return (base: habit.difficulty.xp, bonus: total - habit.difficulty.xp);
  }
}
