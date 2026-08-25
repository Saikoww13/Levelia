import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/core/util/day.dart';
import 'package:levelia/domain/engine/streaks.dart';
import 'package:levelia/domain/models/app_data.dart';
import 'package:levelia/domain/models/habit.dart';
import 'package:levelia/domain/models/habit_log.dart';

/// Construit un état minimal contenant une habitude et les pointages fournis.
AppData _stateWith(Habit habit, Map<DateTime, bool> pointages) {
  final logs = <String, HabitLog>{};
  pointages.forEach((jour, reussi) {
    final log = HabitLog(
      habitId: habit.id,
      day: dayOf(jour),
      done: reussi,
      xpAwarded: reussi ? 10 : 0,
    );
    logs[log.key] = log;
  });
  return AppData(habits: [habit], logs: logs);
}

void main() {
  final reference = DateTime(2026, 8, 25); // un mardi
  DateTime ilYA(int jours) => reference.subtract(Duration(days: jours));

  Habit quotidienne() => Habit(
    id: 'h1',
    title: 'Lire',
    categoryId: 'c1',
    createdAt: ilYA(10),
    schedule: const HabitSchedule.daily(),
  );

  group('Séries au jour le jour', () {
    test('trois jours consécutifs donnent une série de trois', () {
      final habit = quotidienne();
      final data = _stateWith(habit, {
        ilYA(2): true,
        ilYA(1): true,
        reference: true,
      });

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(serie.current, 3);
      expect(serie.best, 3);
      expect(serie.unit, StreakUnit.days);
    });

    test('une journée manquée casse la série', () {
      final habit = quotidienne();
      final data = _stateWith(habit, {
        ilYA(3): true,
        ilYA(2): true,
        ilYA(1): false,
        reference: true,
      });

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(serie.current, 1, reason: 'seule la journée du jour compte');
      expect(serie.best, 2, reason: 'la meilleure série reste mémorisée');
    });

    test('la journée en cours non pointée ne casse pas la série', () {
      final habit = quotidienne();
      final data = _stateWith(habit, {ilYA(2): true, ilYA(1): true});

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(serie.current, 2, reason: 'aujourd\'hui bénéficie d\'un sursis');
    });

    test('une journée passée jamais pointée casse bien la série', () {
      final habit = quotidienne();
      final data = _stateWith(habit, {ilYA(3): true, reference: true});

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(serie.current, 1);
    });

    test('les jours non planifiés sont ignorés', () {
      // Habitude du lundi et du mardi uniquement.
      final habit = Habit(
        id: 'h2',
        title: 'Sport',
        categoryId: 'c1',
        createdAt: ilYA(14),
        schedule: const HabitSchedule.onWeekdays({1, 2}),
      );
      final data = _stateWith(habit, {
        DateTime(2026, 8, 17): true, // lundi
        DateTime(2026, 8, 18): true, // mardi
        DateTime(2026, 8, 24): true, // lundi
        DateTime(2026, 8, 25): true, // mardi (référence)
      });

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(
        serie.current,
        4,
        reason: 'les mercredis à dimanches ne comptent pas',
      );
    });

    test('le taux de réussite ne porte que sur les jours attendus', () {
      final habit = Habit(
        id: 'h3',
        title: 'Méditer',
        categoryId: 'c1',
        createdAt: ilYA(3),
        schedule: const HabitSchedule.daily(),
      );
      final data = _stateWith(habit, {
        ilYA(3): true,
        ilYA(2): false,
        ilYA(1): true,
        reference: true,
      });

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(serie.totalDone, 3);
      expect(serie.completionRate, closeTo(3 / 4, 0.001));
    });
  });

  group('Séries hebdomadaires', () {
    Habit troisFois() => Habit(
      id: 'h4',
      title: 'Courir',
      categoryId: 'c1',
      createdAt: DateTime(2026, 8, 3),
      schedule: const HabitSchedule.timesAWeek(3),
    );

    test('une semaine atteignant la cible compte pour la série', () {
      final habit = troisFois();
      final data = _stateWith(habit, {
        // Semaine du 17 au 23 août : 3 réussites.
        DateTime(2026, 8, 17): true,
        DateTime(2026, 8, 19): true,
        DateTime(2026, 8, 21): true,
        // Semaine en cours : 1 réussite, encore rattrapable.
        DateTime(2026, 8, 24): true,
      });

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(serie.unit, StreakUnit.weeks);
      expect(
        serie.current,
        1,
        reason: 'la semaine en cours est en sursis, seule la précédente compte',
      );
    });

    test('une semaine ratée casse la série hebdomadaire', () {
      final habit = troisFois();
      final data = _stateWith(habit, {
        DateTime(2026, 8, 10): true,
        DateTime(2026, 8, 11): true,
        DateTime(2026, 8, 12): true,
        // Semaine du 17 : une seule sortie, cible non atteinte.
        DateTime(2026, 8, 18): true,
      });

      final serie = Streaks.of(data, habit, asOf: reference);
      expect(serie.current, 0);
      expect(serie.best, 1);
    });
  });

  test('streakBefore renvoie la série de la veille', () {
    final habit = quotidienne();
    final data = _stateWith(habit, {ilYA(2): true, ilYA(1): true});

    expect(Streaks.streakBefore(data, habit, reference), 2);
  });
}
