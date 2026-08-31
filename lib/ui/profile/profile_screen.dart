import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/day.dart';
import '../../domain/models/app_data.dart';
import '../../state/providers.dart';
import '../categories/category_editor.dart';
import '../widgets/category_widgets.dart';
import '../widgets/common.dart';
import '../widgets/level_widgets.dart';
import '../widgets/modal_page.dart';

/// La fiche de personnage : niveau global, domaines, et réglages.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final data = ref.watch(appDataProvider);
    final niveau = data.globalLevel;

    final label = c.label;
    final secondaire = c.secondary;

    return AppPage(
      title: 'Profil',
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LevelMedallion(info: niveau, color: AppTheme.seed),
              Gaps.h16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      data.profileName,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(label, size: 20),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(34, 34),
                    onPressed: () => _renommer(context, ref, data.profileName),
                    child: Icon(
                      CupertinoIcons.pencil,
                      size: 17,
                      color: AppTheme.seed,
                      semanticLabel: 'Changer de nom',
                    ),
                  ),
                ],
              ),
              Gaps.h8,
              Text(
                niveau.xpForNextLevel <= 0
                    ? '${niveau.totalXp} XP au compteur'
                    : 'Encore ${niveau.xpRemaining} XP avant le niveau ${niveau.level + 1}',
                textAlign: TextAlign.center,
                style: AppText.caption(secondaire),
              ),
            ],
          ),
        ),

        Gaps.h24,
        SectionTitle(
          title: 'Domaines',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            onPressed: () => openCategoryEditor(context, ref),
            child: const Text('Ajouter', style: TextStyle(fontSize: 14)),
          ),
        ),
        if (data.activeCategories.isEmpty)
          AppCard(
            child: Text(
              'Crée un premier domaine pour y ranger tes habitudes et tes objectifs.',
              style: AppText.body(secondaire),
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
                  CategoryAvatar(category: categorie, size: 40),
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
                                style: AppText.title(label, size: 15),
                              ),
                            ),
                            Text(
                              plural(
                                data.habitsOf(categorie.id).length,
                                'habitude',
                              ),
                              style: AppText.caption(secondaire, size: 12),
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
        AppSegmented<AppearanceMode>(
          value: data.themeMode,
          onChanged: (mode) =>
              ref.read(appControllerProvider.notifier).setThemeMode(mode),
          children: {
            for (final mode in AppearanceMode.values)
              mode: SegmentLabel(mode.label),
          },
        ),

        Gaps.h24,
        const SectionTitle(title: 'Tes données'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: CupertinoIcons.square_arrow_up,
                title: 'Exporter une sauvegarde',
                subtitle: 'Copie tout ton historique au format JSON',
                onTap: () => _exporter(context, ref),
              ),
              const _RowDivider(),
              _SettingRow(
                icon: CupertinoIcons.square_arrow_down,
                title: 'Importer une sauvegarde',
                subtitle: 'Remplace les données actuelles',
                onTap: () => _importer(context, ref),
              ),
              const _RowDivider(),
              _SettingRow(
                icon: CupertinoIcons.book,
                title: 'Revoir l\'introduction',
                subtitle: 'Réaffiche les explications au prochain démarrage',
                onTap: () => _revoirIntro(context, ref),
              ),
              const _RowDivider(),
              _SettingRow(
                icon: CupertinoIcons.arrow_counterclockwise,
                title: 'Tout réinitialiser',
                subtitle: 'Repart des domaines d\'origine',
                destructive: true,
                onTap: () => _reinitialiser(context, ref),
              ),
            ],
          ),
        ),

        Gaps.h24,
        Center(
          child: Text(
            'Levelia · tes données restent sur cet appareil',
            style: AppText.caption(secondaire, size: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _renommer(
    BuildContext context,
    WidgetRef ref,
    String actuel,
  ) async {
    final saisie = TextEditingController(text: actuel);

    final nom = await showCupertinoDialog<String>(
      context: context,
      builder: (contexte) => CupertinoAlertDialog(
        title: const Text('Ton nom'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: saisie,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            placeholder: 'Comment t\'appeler ?',
            onSubmitted: (valeur) => Navigator.of(contexte).pop(valeur),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(contexte).pop(),
            child: const Text('Annuler'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(contexte).pop(saisie.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    saisie.dispose();

    if (nom != null && nom.trim().isNotEmpty) {
      await ref.read(appControllerProvider.notifier).renameProfile(nom);
    }
  }

  Future<void> _exporter(BuildContext context, WidgetRef ref) async {
    final json = ref.read(appControllerProvider.notifier).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    await showNotice(
      context,
      title: 'Sauvegarde copiée',
      message:
          '${json.length} caractères sont dans le presse-papiers. '
          'Colle-les dans un fichier pour les conserver.',
    );
  }

  Future<void> _importer(BuildContext context, WidgetRef ref) async {
    final json = await showAppModal<String>(
      context: context,
      builder: (_) => const _ImportPage(),
    );

    if (json == null || json.trim().isEmpty || !context.mounted) return;

    try {
      await ref.read(appControllerProvider.notifier).importJson(json);
      if (!context.mounted) return;
      await showNotice(context, title: 'Sauvegarde restaurée');
    } on FormatException {
      if (!context.mounted) return;
      await showNotice(
        context,
        title: 'Contenu invalide',
        message: 'Ce texte n\'est pas une sauvegarde Levelia.',
      );
    }
  }

  Future<void> _revoirIntro(BuildContext context, WidgetRef ref) async {
    // Rien n'est effacé : seule la marque « déjà vue » est retirée, et
    // l'application rouvre sur l'introduction.
    await ref.read(appControllerProvider.notifier).replayOnboarding();
  }

  Future<void> _reinitialiser(BuildContext context, WidgetRef ref) async {
    final confirme = await confirmDestructive(
      context,
      title: 'Tout réinitialiser ?',
      message:
          'Habitudes, objectifs, historique et XP seront effacés sans retour '
          'possible. Pense à exporter une sauvegarde avant.',
      confirmLabel: 'Réinitialiser',
    );

    if (!confirme) return;
    await ref.read(appControllerProvider.notifier).resetAll();
  }
}

/// Page modale de collage d'une sauvegarde.
class _ImportPage extends StatefulWidget {
  const _ImportPage();

  @override
  State<_ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<_ImportPage> {
  final _saisie = TextEditingController()..addListener(() {});

  @override
  void initState() {
    super.initState();
    _saisie.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final secondaire = c.secondary;

    return AppFormPage(
      title: 'Importer',
      actionLabel: 'Importer',
      onAction: _saisie.text.trim().isEmpty
          ? null
          : () => Navigator.of(context).pop(_saisie.text),
      children: [
        Text(
          'Colle ici le contenu JSON d\'une sauvegarde. Les données actuelles '
          'seront intégralement remplacées.',
          style: AppText.body(secondaire, size: 14),
        ),
        Gaps.h16,
        AppTextField(
          controller: _saisie,
          placeholder: '{ "schemaVersion": 1, … }',
          maxLines: 10,
          textCapitalization: TextCapitalization.none,
          style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
        ),
      ],
    );
  }
}

/// Ligne de réglage, au format des listes iOS.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = c.label;
    final secondaire = c.secondary;
    final teinte = destructive ? AppTheme.missed : AppTheme.seed;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: teinte),
          Gaps.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(destructive ? AppTheme.missed : label),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption(secondaire, size: 12)),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_forward, size: 15, color: c.tertiary),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Container(height: 0.5, color: c.separator),
    );
  }
}
