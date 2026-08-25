import '../../core/util/day.dart';
import '../models/app_data.dart';
import '../models/habit.dart';

/// Unité dans laquelle se compte une série.
enum StreakUnit {
  days,
  weeks;

  /// Libellé accordé au nombre : « 1 jour », « 3 semaines ».
  String labelFor(int count) => switch (this) {
    StreakUnit.days => count <= 1 ? 'jour' : 'jours',
    StreakUnit.weeks => count <= 1 ? 'semaine' : 'semaines',
  };
}

/// Ce que l'on sait de la régularité d'une habitude.
class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.unit,
    required this.completionRate,
    required this.totalDone,
  });

  static const StreakInfo empty = StreakInfo(
    current: 0,
    best: 0,
    unit: StreakUnit.days,
    completionRate: 0,
    totalDone: 0,
  );

  /// Série en cours.
  final int current;

  /// Meilleure série jamais atteinte.
  final int best;

  final StreakUnit unit;

  /// Taux de réussite sur les jours attendus, entre 0 et 1.
  final double completionRate;

  /// Nombre total de journées réussies.
  final int totalDone;

  String get currentLabel => '$current ${unit.labelFor(current)}';
  String get bestLabel => '$best ${unit.labelFor(best)}';
}

/// Calculs de régularité d'une habitude à partir de ses pointages.
class Streaks {
  const Streaks._();

  /// Analyse complète d'une habitude à la date [asOf] (par défaut aujourd'hui).
  static StreakInfo of(AppData data, Habit habit, {DateTime? asOf}) {
    final fin = dayOf(asOf ?? DateTime.now());
    final debut = dayOf(habit.createdAt);
    if (fin.isBefore(debut)) return StreakInfo.empty;

    return habit.schedule.isDayStrict
        ? _strict(data, habit, debut, fin)
        : _weekly(data, habit, debut, fin);
  }

  /// Série d'une habitude jugée au jour le jour.
  ///
  /// Les journées non attendues sont ignorées. La journée en cours bénéficie
  /// d'un sursis : tant qu'elle n'est pas pointée, elle ne casse pas la série.
  static StreakInfo _strict(
    AppData data,
    Habit habit,
    DateTime debut,
    DateTime fin,
  ) {
    var meilleure = 0;
    var enCours = 0;
    var attendus = 0;
    var reussis = 0;

    // Parcours chronologique pour la meilleure série et le taux de réussite.
    for (var j = debut; !j.isAfter(fin); j = j.add(const Duration(days: 1))) {
      if (!habit.schedule.isDueOn(j)) continue;

      final log = data.logFor(habit.id, j);
      final estAujourdhui = isSameDay(j, fin);

      if (log != null && log.done) {
        enCours++;
        reussis++;
        attendus++;
        if (enCours > meilleure) meilleure = enCours;
      } else if (log == null && estAujourdhui) {
        // Sursis : la journée en cours n'est pas encore jouée.
        continue;
      } else {
        enCours = 0;
        attendus++;
      }
    }

    // La série courante est celle qui se termine à la fin du parcours.
    return StreakInfo(
      current: enCours,
      best: meilleure,
      unit: StreakUnit.days,
      completionRate: attendus == 0 ? 0 : reussis / attendus,
      totalDone: reussis,
    );
  }

  /// Série d'une habitude « N fois par semaine », jugée à la semaine.
  ///
  /// La semaine en cours ne casse pas la série tant qu'elle n'est pas finie.
  static StreakInfo _weekly(
    AppData data,
    Habit habit,
    DateTime debut,
    DateTime fin,
  ) {
    final cible = habit.schedule.expectedPerWeek;
    var meilleure = 0;
    var enCours = 0;
    var semaines = 0;
    var semainesReussies = 0;
    var totalReussis = 0;

    final premiereSemaine = startOfWeek(debut);
    final derniereSemaine = startOfWeek(fin);

    for (
      var lundi = premiereSemaine;
      !lundi.isAfter(derniereSemaine);
      lundi = lundi.add(const Duration(days: 7))
    ) {
      final faits = _doneInWeek(data, habit, lundi, debut, fin);
      totalReussis += faits;

      final estSemaineCourante = isSameDay(lundi, derniereSemaine);
      final atteinte = cible <= 0 || faits >= cible;

      if (atteinte) {
        enCours++;
        semaines++;
        semainesReussies++;
        if (enCours > meilleure) meilleure = enCours;
      } else if (estSemaineCourante) {
        // Sursis : la semaine en cours peut encore être rattrapée.
        continue;
      } else {
        enCours = 0;
        semaines++;
      }
    }

    return StreakInfo(
      current: enCours,
      best: meilleure,
      unit: StreakUnit.weeks,
      completionRate: semaines == 0 ? 0 : semainesReussies / semaines,
      totalDone: totalReussis,
    );
  }

  /// Nombre de journées réussies dans la semaine commençant le [lundi],
  /// bornée à la période de vie de l'habitude.
  static int _doneInWeek(
    AppData data,
    Habit habit,
    DateTime lundi,
    DateTime debut,
    DateTime fin,
  ) {
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final j = lundi.add(Duration(days: i));
      if (j.isBefore(debut) || j.isAfter(fin)) continue;
      final log = data.logFor(habit.id, j);
      if (log != null && log.done) total++;
    }
    return total;
  }

  /// Série telle qu'elle était *avant* de pointer [day], pour calculer le bonus d'XP.
  static int streakBefore(AppData data, Habit habit, DateTime day) {
    final veille = dayOf(day).subtract(const Duration(days: 1));
    if (veille.isBefore(dayOf(habit.createdAt))) return 0;
    return of(data, habit, asOf: veille).current;
  }
}
