import '../domain/models/app_data.dart';

/// Palette proposée lors de la création d'un domaine.
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

/// Emojis proposés lors de la création d'un domaine.
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

/// Un domaine proposé à la création, pendant l'introduction.
class SuggestedCategory {
  const SuggestedCategory(this.name, this.emoji, this.colorValue);

  final String name;
  final String emoji;
  final int colorValue;
}

/// Domaines suggérés au premier lancement.
///
/// Ce ne sont que des propositions : l'utilisateur en choisit, les ignore, ou
/// crée les siens. Rien n'est imposé — c'est la différence avec des exemples
/// pré-remplis, qu'il aurait fallu supprimer un par un.
const List<SuggestedCategory> suggestedCategories = [
  SuggestedCategory('Corps', '💪', 0xFFFF7043),
  SuggestedCategory('Esprit', '🧠', 0xFF7C4DFF),
  SuggestedCategory('Travail', '🎯', 0xFF29B6F6),
  SuggestedCategory('Relations', '❤️', 0xFFEC407A),
  SuggestedCategory('Discipline', '⚔️', 0xFF26A69A),
];

/// Idées d'habitudes proposées pendant l'introduction, selon le domaine choisi.
const Map<String, List<String>> suggestedHabits = {
  'Corps': ['Bouger 30 minutes', 'Boire 2 litres d\'eau', 'Dormir avant 23 h'],
  'Esprit': ['Lire 10 pages', 'Méditer 10 minutes', 'Apprendre un mot'],
  'Travail': [
    'Une session sans distraction',
    'Ranger mon bureau',
    'Planifier demain',
  ],
  'Relations': [
    'Prendre des nouvelles de quelqu\'un',
    'Un vrai repas sans écran',
  ],
  'Discipline': [
    'Pas de réseaux sociaux le matin',
    'Faire mon lit',
    'Pas d\'écran après 22 h',
  ],
};

/// L'état initial : vide.
///
/// L'introduction se charge de faire créer le premier domaine et la première
/// habitude. Des exemples pré-remplis auraient obligé l'utilisateur à faire le
/// ménage avant de commencer, et auraient fait démarrer sa progression sur des
/// habitudes qui ne sont pas les siennes.
AppData buildSeedData() => const AppData();
