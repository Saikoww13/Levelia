import '../core/util/day.dart';
import '../domain/models/app_data.dart';
import '../domain/models/category.dart';
import '../domain/models/goal.dart';
import '../domain/models/habit.dart';

/// Palette proposée par défaut lors de la création d'une catégorie.
const List<int> categoryPalette = [
  0xFFFF7043, // corail
  0xFF7C4DFF, // violet
  0xFF29B6F6, // bleu ciel
  0xFFEC407A, // rose
  0xFF26A69A, // turquoise
  0xFFFFCA28, // ambre
  0xFF66BB6A, // vert
  0xFF8D6E63, // brun
];

/// Emojis proposés lors de la création d'une catégorie.
const List<String> categoryEmojis = [
  '💪',
  '🧠',
  '🎯',
  '❤️',
  '⚔️',
  '🎨',
  '💰',
  '🌱',
  '📚',
  '🧘',
  '🔥',
  '⭐',
];

/// L'état initial au tout premier lancement.
///
/// On propose des catégories et quelques habitudes d'exemple plutôt qu'un écran
/// vide : l'utilisateur voit immédiatement à quoi ressemble l'application, et
/// peut tout renommer ou supprimer.
AppData buildSeedData() {
  final maintenant = today();

  const categories = [
    Category(
      id: 'cat-corps',
      name: 'Corps',
      emoji: '💪',
      colorValue: 0xFFFF7043,
      sortIndex: 0,
    ),
    Category(
      id: 'cat-esprit',
      name: 'Esprit',
      emoji: '🧠',
      colorValue: 0xFF7C4DFF,
      sortIndex: 1,
    ),
    Category(
      id: 'cat-travail',
      name: 'Travail',
      emoji: '🎯',
      colorValue: 0xFF29B6F6,
      sortIndex: 2,
    ),
    Category(
      id: 'cat-relations',
      name: 'Relations',
      emoji: '❤️',
      colorValue: 0xFFEC407A,
      sortIndex: 3,
    ),
    Category(
      id: 'cat-discipline',
      name: 'Discipline',
      emoji: '⚔️',
      colorValue: 0xFF26A69A,
      sortIndex: 4,
    ),
  ];

  final habitudes = [
    Habit(
      id: 'habit-sport',
      title: 'Bouger 30 minutes',
      note: 'Marche rapide, muscu ou vélo — tout compte.',
      categoryId: 'cat-corps',
      difficulty: HabitDifficulty.normal,
      schedule: const HabitSchedule.timesAWeek(4),
      createdAt: maintenant,
      sortIndex: 0,
    ),
    Habit(
      id: 'habit-lecture',
      title: 'Lire 10 pages',
      categoryId: 'cat-esprit',
      difficulty: HabitDifficulty.easy,
      schedule: const HabitSchedule.daily(),
      createdAt: maintenant,
      sortIndex: 1,
    ),
    Habit(
      id: 'habit-deep-work',
      title: 'Une session sans distraction',
      note: 'Téléphone en mode avion, une seule tâche.',
      categoryId: 'cat-travail',
      difficulty: HabitDifficulty.hard,
      schedule: const HabitSchedule.onWeekdays({1, 2, 3, 4, 5}),
      createdAt: maintenant,
      sortIndex: 2,
    ),
    Habit(
      id: 'habit-ecrans',
      title: 'Pas de réseaux sociaux le matin',
      categoryId: 'cat-discipline',
      polarity: HabitPolarity.negative,
      difficulty: HabitDifficulty.normal,
      schedule: const HabitSchedule.daily(),
      createdAt: maintenant,
      sortIndex: 3,
    ),
  ];

  final objectifs = [
    Goal(
      id: 'goal-demo',
      title: 'Tenir 30 jours de régularité',
      description:
          'Premier palier : prouver que le système fonctionne pour moi.',
      categoryId: 'cat-discipline',
      createdAt: maintenant,
      targetDate: maintenant.add(const Duration(days: 30)),
      milestones: const [
        Milestone(id: 'ms-1', title: 'Tenir la première semaine'),
        Milestone(id: 'ms-2', title: 'Atteindre 15 jours'),
        Milestone(id: 'ms-3', title: 'Boucler les 30 jours'),
      ],
    ),
  ];

  return AppData(
    categories: categories,
    habits: habitudes,
    goals: objectifs,
    updatedAt: DateTime.now(),
  );
}
