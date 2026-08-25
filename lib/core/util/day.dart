/// Utilitaires de dates. Dans Levelia une « journée » est toujours normalisée à
/// minuit heure locale, et sérialisée au format `yyyy-MM-dd`.
library;

/// Ramène [date] à minuit, en supprimant l'heure.
DateTime dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

/// La journée en cours.
DateTime today() => dayOf(DateTime.now());

/// Clé de sérialisation stable d'une journée : `2026-08-25`.
String dayKey(DateTime date) {
  final d = dayOf(date);
  final m = d.month.toString().padLeft(2, '0');
  final j = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$j';
}

/// Relit une clé produite par [dayKey].
DateTime parseDayKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Nombre de journées entières entre deux dates (positif si [to] est après [from]).
///
/// Passe par les composantes de date plutôt que par [Duration] pour rester juste
/// lors des changements d'heure été/hiver.
int daysBetween(DateTime from, DateTime to) =>
    dayOf(to).difference(dayOf(from)).inDays;

/// Le lundi de la semaine contenant [date].
DateTime startOfWeek(DateTime date) {
  final d = dayOf(date);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// Les 7 journées de la semaine contenant [date], du lundi au dimanche.
List<DateTime> weekDays(DateTime date) {
  final lundi = startOfWeek(date);
  return List.generate(7, (i) => lundi.add(Duration(days: i)));
}

/// Vrai si les deux dates tombent le même jour.
bool isSameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

const List<String> weekdayLabelsShort = [
  'Lun',
  'Mar',
  'Mer',
  'Jeu',
  'Ven',
  'Sam',
  'Dim',
];

const List<String> monthLabels = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Libellé lisible d'une journée : « lundi 25 août 2026 ».
String longDayLabel(DateTime date) {
  const jours = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  final d = dayOf(date);
  return '${jours[d.weekday - 1]} ${d.day} ${monthLabels[d.month - 1]} ${d.year}';
}

/// Libellé court : « 25 août ».
String shortDayLabel(DateTime date) {
  final d = dayOf(date);
  return '${d.day} ${monthLabels[d.month - 1]}';
}

/// Accorde un nom au singulier ou au pluriel selon [count].
///
/// `plural(1, 'habitude')` → « 1 habitude », `plural(3, 'habitude')` → « 3 habitudes ».
String plural(int count, String singular, [String? pluralForm]) {
  final mot = count <= 1 ? singular : (pluralForm ?? '${singular}s');
  return '$count $mot';
}
