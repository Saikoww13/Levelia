import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/models/app_data.dart';
import 'repository.dart';
import 'seed.dart';

/// Persistance locale dans un unique fichier JSON, sous le dossier de données
/// de l'application.
///
/// Un document unique convient très bien à ce volume (quelques milliers de
/// pointages au maximum) et présente deux avantages : aucune dépendance native
/// à compiler sur les cinq plateformes, et un format directement transposable
/// en charge utile de synchro le jour venu.
class JsonFileRepository implements LeveliaRepository {
  JsonFileRepository({this.fileName = 'levelia_data.json'});

  final String fileName;

  File? _cachedFile;

  Future<File> _file() async {
    final existant = _cachedFile;
    if (existant != null) return existant;

    final dossier = await getApplicationSupportDirectory();
    if (!await dossier.exists()) {
      await dossier.create(recursive: true);
    }
    final fichier = File('${dossier.path}${Platform.pathSeparator}$fileName');
    _cachedFile = fichier;
    return fichier;
  }

  @override
  Future<AppData> load() async {
    final fichier = await _file();

    if (!await fichier.exists()) {
      final depart = buildSeedData();
      await save(depart);
      return depart;
    }

    try {
      final brut = await fichier.readAsString();
      if (brut.trim().isEmpty) return buildSeedData();
      final json = jsonDecode(brut) as Map<String, dynamic>;
      return AppData.fromJson(json);
    } on FormatException {
      // Fichier corrompu : on le met de côté plutôt que de le perdre
      // silencieusement, et on repart d'un état propre.
      await _quarantine(fichier);
      return buildSeedData();
    }
  }

  @override
  Future<void> save(AppData data) async {
    final fichier = await _file();
    final contenu = const JsonEncoder.withIndent(
      '  ',
    ).convert(data.copyWith(updatedAt: DateTime.now()).toJson());

    // Écriture atomique : on passe par un fichier temporaire puis on renomme,
    // pour ne jamais laisser un JSON tronqué si l'app est tuée en plein écrit.
    final temporaire = File('${fichier.path}.tmp');
    await temporaire.writeAsString(contenu, flush: true);
    await temporaire.rename(fichier.path);
  }

  Future<void> _quarantine(File fichier) async {
    final horodatage = DateTime.now().millisecondsSinceEpoch;
    try {
      await fichier.rename('${fichier.path}.corrupt-$horodatage');
    } on FileSystemException {
      // Si même le renommage échoue, mieux vaut continuer avec un état neuf
      // que de bloquer le démarrage de l'application.
    }
  }
}

/// Implémentation en mémoire, utile pour les tests et les aperçus.
class InMemoryRepository implements LeveliaRepository {
  InMemoryRepository([AppData? initial]) : _data = initial ?? buildSeedData();

  AppData _data;

  @override
  Future<AppData> load() async => _data;

  @override
  Future<void> save(AppData data) async {
    _data = data;
  }
}
