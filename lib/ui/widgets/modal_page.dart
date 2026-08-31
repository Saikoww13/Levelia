import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';

/// Présente un formulaire en page modale, façon iOS.
///
/// Sur iOS un formulaire ne monte pas en demi-feuille : il se présente en carte
/// plein écran qui glisse depuis le bas, avec « Annuler » à gauche et l'action
/// de validation à droite dans la barre. `fullscreenDialog` donne exactement
/// cette présentation, y compris le geste de fermeture vers le bas.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(CupertinoPageRoute<T>(fullscreenDialog: true, builder: builder));
}

/// Ossature d'une page de formulaire modale.
class AppFormPage extends StatelessWidget {
  const AppFormPage({
    super.key,
    required this.title,
    required this.children,
    required this.actionLabel,
    required this.onAction,
    this.onDelete,
    this.deleteLabel = 'Supprimer',
  });

  final String title;
  final List<Widget> children;

  /// Libellé de l'action de droite : « Créer », « Enregistrer », « Importer ».
  final String actionLabel;

  /// `null` désactive l'action (enregistrement en cours, par exemple).
  final VoidCallback? onAction;

  /// Action destructrice, présentée en bas du formulaire comme sur iOS.
  final VoidCallback? onDelete;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final clavier = MediaQuery.viewInsetsOf(context).bottom;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: c.bar,
        border: Border(bottom: BorderSide(color: c.separator, width: 0.5)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        middle: Text(title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + clavier),
          children: [
            ...children,
            if (onDelete != null) ...[
              Gaps.h32,
              CupertinoButton(
                onPressed: onDelete,
                child: Text(
                  deleteLabel,
                  style: const TextStyle(
                    color: AppTheme.missed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Champ de saisie au format iOS : fond uni, coins arrondis, pas de soulignement.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.autofocus = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.sentences,
    this.style,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return CupertinoTextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      placeholder: placeholder,
      style: style,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      placeholderStyle: TextStyle(color: c.tertiary),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.separator, width: 0.5),
      ),
    );
  }
}

/// Boîte de confirmation iOS pour une action destructrice.
///
/// Renvoie `true` si l'utilisateur confirme.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Supprimer',
}) async {
  final reponse = await showCupertinoDialog<bool>(
    context: context,
    builder: (contexte) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(contexte).pop(false),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(contexte).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return reponse ?? false;
}

/// Message d'information bref, au format iOS.
Future<void> showNotice(
  BuildContext context, {
  required String title,
  String? message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (contexte) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message),
            ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(contexte).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
