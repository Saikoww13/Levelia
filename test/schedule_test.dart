import 'package:flutter_test/flutter_test.dart';
import 'package:levelia/domain/models/habit.dart';

void main() {
  // 2026-08-24 est un lundi, 2026-08-30 le dimanche qui suit.
  final lundi = DateTime(2026, 8, 24);
  final mercredi = DateTime(2026, 8, 26);
  final samedi = DateTime(2026, 8, 29);

  group('HabitSchedule', () {
    test('quotidienne : attendue tous les jours', () {
      const planif = HabitSchedule.daily();
      expect(planif.isDueOn(lundi), isTrue);
      expect(planif.isDueOn(samedi), isTrue);
      expect(planif.expectedPerWeek, 7);
      expect(planif.isDayStrict, isTrue);
    });

    test('jours choisis : n\'est attendue que ces jours-là', () {
      const planif = HabitSchedule.onWeekdays({1, 3, 5});
      expect(planif.isDueOn(lundi), isTrue);
      expect(planif.isDueOn(mercredi), isTrue);
      expect(planif.isDueOn(samedi), isFalse);
      expect(planif.expectedPerWeek, 3);
    });

    test('N fois par semaine : aucun jour n\'est imposé', () {
      const planif = HabitSchedule.timesAWeek(4);
      expect(planif.isDueOn(lundi), isTrue);
      expect(planif.isDueOn(samedi), isTrue);
      expect(planif.expectedPerWeek, 4);
      // La série se juge à la semaine, pas au jour.
      expect(planif.isDayStrict, isFalse);
    });

    test('les libellés sont lisibles', () {
      expect(const HabitSchedule.daily().label, 'Tous les jours');
      expect(const HabitSchedule.onWeekdays({1, 5}).label, 'Lun, Ven');
      expect(const HabitSchedule.timesAWeek(3).label, '3× par semaine');
    });

    test('la sérialisation fait un aller-retour fidèle', () {
      const original = HabitSchedule.onWeekdays({2, 4, 6});
      final relu = HabitSchedule.fromJson(original.toJson());
      expect(relu.kind, original.kind);
      expect(relu.weekdays, original.weekdays);
    });
  });
}
