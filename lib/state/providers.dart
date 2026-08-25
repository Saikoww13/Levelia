import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/util/day.dart';
import '../data/json_file_repository.dart';
import '../data/repository.dart';
import '../domain/engine/streaks.dart';
import '../domain/models/app_data.dart';
import '../domain/models/habit.dart';
import '../domain/models/habit_log.dart';
import 'app_controller.dart';

/// Implémentation de persistance utilisée par l'application.
///
/// Surchargée dans les tests (et un jour par une implémentation synchronisée)
/// via `ProviderScope(overrides: [...])`.
final repositoryProvider = Provider<LeveliaRepository>(
  (ref) => JsonFileRepository(),
);

/// Source de vérité unique de l'application.
final appControllerProvider = AsyncNotifierProvider<AppController, AppData>(
  AppController.new,
);

/// Raccourci vers l'état chargé.
///
/// À n'utiliser que sous un `AsyncValue.when(data: ...)`, une fois le
/// chargement initial terminé.
final appDataProvider = Provider<AppData>((ref) {
  return ref.watch(appControllerProvider).requireValue;
});

/// Journée affichée dans l'écran « Aujourd'hui ». Permet de revenir en arrière
/// pour rattraper un pointage oublié.
final selectedDayProvider = StateProvider<DateTime>((ref) => today());

/// Filtre de catégorie appliqué aux listes. `null` = toutes.
final categoryFilterProvider = StateProvider<String?>((ref) => null);

/// Une habitude telle qu'affichée pour une journée : son pointage et sa série.
class HabitEntry {
  const HabitEntry({
    required this.habit,
    required this.log,
    required this.streak,
  });

  final Habit habit;

  /// Pointage de la journée. `null` si la journée n'est pas encore renseignée.
  final HabitLog? log;

  final StreakInfo streak;

  bool get isDone => log?.done ?? false;
  bool get isMissed => log != null && !log!.done;
  bool get isPending => log == null;
}

/// Les habitudes attendues pour la journée sélectionnée, prêtes à afficher.
final dayEntriesProvider = Provider<List<HabitEntry>>((ref) {
  final data = ref.watch(appDataProvider);
  final jour = ref.watch(selectedDayProvider);
  final filtre = ref.watch(categoryFilterProvider);

  final entries = <HabitEntry>[];
  for (final habitude in data.activeHabits) {
    if (filtre != null && habitude.categoryId != filtre) continue;
    if (dayOf(jour).isBefore(dayOf(habitude.createdAt))) continue;
    if (!habitude.schedule.isDueOn(jour)) continue;

    entries.add(
      HabitEntry(
        habit: habitude,
        log: data.logFor(habitude.id, jour),
        streak: Streaks.of(data, habitude, asOf: jour),
      ),
    );
  }
  return entries;
});

/// Avancement de la journée sélectionnée : réussies / attendues.
final dayProgressProvider = Provider<({int done, int total, double ratio})>((
  ref,
) {
  final entries = ref.watch(dayEntriesProvider);
  final faites = entries.where((e) => e.isDone).length;
  final total = entries.length;
  return (
    done: faites,
    total: total,
    ratio: total == 0 ? 0.0 : faites / total,
  );
});

/// XP gagnée sur la journée sélectionnée.
final dayXpProvider = Provider<int>((ref) {
  final data = ref.watch(appDataProvider);
  final jour = ref.watch(selectedDayProvider);
  var total = 0;
  for (final log in data.logs.values) {
    if (log.done && isSameDay(log.day, jour)) total += log.xpAwarded;
  }
  return total;
});
