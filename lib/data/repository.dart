import '../domain/models/app_data.dart';

/// Contrat de persistance de Levelia.
///
/// Toute l'application ne connaît que cette interface. Aujourd'hui une seule
/// implémentation existe ([JsonFileRepository], purement locale) ; brancher une
/// synchro cloud plus tard consistera à en fournir une seconde, sans toucher à
/// l'interface utilisateur ni au domaine.
abstract class LeveliaRepository {
  /// Relit l'état complet. Doit renvoyer un état exploitable même en l'absence
  /// de données antérieures.
  Future<AppData> load();

  /// Écrit l'état complet.
  Future<void> save(AppData data);
}
