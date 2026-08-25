import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/app_data.dart';
import '../../state/app_controller.dart';

/// Affiche le retour visuel d'un gain (ou d'une reprise) d'XP.
///
/// Un passage de niveau mérite un message plus appuyé qu'un simple « +15 XP ».
void showXpFeedback(BuildContext context, AppData data, XpEvent? event) {
  if (event == null || event.xpDelta == 0) return;
  if (!context.mounted) return;

  final categorie = data.categoryById(event.categoryId);
  final couleur = categorie?.color ?? AppTheme.success;
  final gain = event.xpDelta > 0;

  final messager = ScaffoldMessenger.maybeOf(context);
  if (messager == null) return;

  messager
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: event.leveledUp ? 2600 : 1500),
        backgroundColor: event.leveledUp
            ? couleur
            : Theme.of(context).colorScheme.inverseSurface,
        content: Row(
          children: [
            Text(
              event.leveledUp ? '🎉' : (gain ? '✨' : '↩️'),
              style: const TextStyle(fontSize: 18),
            ),
            Gaps.w12,
            Expanded(
              child: Text(
                event.leveledUp
                    ? '${categorie?.name ?? 'Catégorie'} passe niveau ${event.newLevel} !'
                    : gain
                    ? '+${event.xpDelta} XP · ${categorie?.name ?? ''}'
                    : '${event.xpDelta} XP repris',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
}
