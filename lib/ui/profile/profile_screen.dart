import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../state/providers.dart';
import '../categories/category_editor.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import '../widgets/sheet.dart';

/// La fiche de personnage : niveau global, domaines, et réglages.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final theme = Theme.of(context);
    final niveau = data.globalLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                LevelMedallion(
                  info: niveau,
                  color: theme.colorScheme.primary,
                ),
                Gaps.h16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        data.profileName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Changer de nom',
                      onPressed: () => _renommer(context, ref, data.profileName),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                ),
                Text(
                  niveau.rank,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.h16,
                Text(
                  niveau.xpForNextLevel <= 0
                      ? '${niveau.totalXp} XP au compteur'
                      : 'Encore ${niveau.xpRemaining} XP avant le niveau ${niveau.level + 1}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Gaps.h24,
          SectionTitle(
            title: 'Domaines',
            trailing: TextButton.icon(
              onPressed: () => openCategoryEditor(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ),
          if (data.activeCategories.isEmpty)
            const AppCard(
              child: Text(
                'Crée un premier domaine pour y ranger tes habitudes et tes objectifs.',
              ),
            )
          else
            for (final categorie in data.activeCategories) ...[
              AppCard(
                accent: categorie.color,
                onTap: () =>
                    openCategoryEditor(context, ref, category: categorie),
                child: Row(
                  children: [
                    CategoryAvatar(category: categorie, size: 42),
                    Gaps.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  categorie.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                plural(
                                  data.habitsOf(categorie.id).length,
                                  'habitude',
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Gaps.h8,
                          XpBar(
                            info: categorie.levelInfo,
                            color: categorie.color,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Gaps.h8,
            ],

          Gaps.h24,
          const SectionTitle(title: 'Apparence'),
          AppCard(
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Auto'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Clair'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Sombre'),
                ),
              ],
              selected: {data.themeMode},
              onSelectionChanged: (choix) => ref
                  .read(appControllerProvider.notifier)
                  .setThemeMode(choix.first),
            ),
          ),

          Gaps.h24,
          const SectionTitle(title: 'Tes données'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('Exporter une sauvegarde'),
                  subtitle: const Text(
                    'Copie tout ton historique au format JSON',
                  ),
                  onTap: () => _exporter(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Importer une sauvegarde'),
                  subtitle: const Text('Remplace les données actuelles'),
                  onTap: () => _importer(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.restart_alt,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Tout réinitialiser',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Repart des catégories d\'origine'),
                  onTap: () => _reinitialiser(context, ref),
                ),
              ],
            ),
          ),

          Gaps.h24,
          Center(
            child: Text(
              'Levelia · tes données restent sur cet appareil',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renommer(
    BuildContext context,
    WidgetRef ref,
    String actuel,
  ) async {
    final controleur = TextEditingController(text: actuel);
    final nom = await showDialog<String>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: const Text('Ton nom'),
        content: TextField(
          controller: controleur,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Comment t\'appeler ?'),
          onSubmitted: (valeur) => Navigator.of(contexte).pop(valeur),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexte).pop(controleur.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    controleur.dispose();

    if (nom != null && nom.trim().isNotEmpty) {
      await ref.read(appControllerProvider.notifier).renameProfile(nom);
    }
  }

  Future<void> _exporter(BuildContext context, WidgetRef ref) async {
    final json = ref.read(appControllerProvider.notifier).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sauvegarde copiée dans le presse-papiers (${json.length} caractères). '
          'Colle-la dans un fichier pour la conserver.',
        ),
      ),
    );
  }

  Future<void> _importer(BuildContext context, WidgetRef ref) async {
    final saisie = TextEditingController();

    final json = await showAppSheet<String>(
      context: context,
      title: 'Importer une sauvegarde',
      builder: (contexte) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Colle ici le contenu JSON d\'une sauvegarde. Les données actuelles '
            'seront intégralement remplacées.',
          ),
          Gaps.h16,
          TextField(
            controller: saisie,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(hintText: '{ "schemaVersion": 1, ... }'),
          ),
          Gaps.h16,
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(contexte).pop(saisie.text),
              child: const Text('Importer'),
            ),
          ),
        ],
      ),
    );

    saisie.dispose();
    if (json == null || json.trim().isEmpty || !context.mounted) return;

    try {
      await ref.read(appControllerProvider.notifier).importJson(json);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sauvegarde restaurée.')));
    } on FormatException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce contenu n\'est pas une sauvegarde valide.'),
        ),
      );
    }
  }

  Future<void> _reinitialiser(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: const Text('Tout réinitialiser ?'),
        content: const Text(
          'Habitudes, objectifs, historique et XP seront effacés sans retour '
          'possible. Pense à exporter une sauvegarde avant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexte).pop(true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirme != true) return;
    await ref.read(appControllerProvider.notifier).resetAll();
  }
}
