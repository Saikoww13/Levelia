import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/app_data.dart';
import '../../state/app_controller.dart';
import 'level_up.dart';

/// Bannière d'XP actuellement affichée, s'il y en a une.
///
/// Conservée au niveau de la bibliothèque pour qu'un pointage rapide remplace
/// la bannière précédente au lieu d'en empiler plusieurs.
OverlayEntry? _banniereCourante;

/// Affiche le retour visuel d'un gain (ou d'une reprise) d'XP.
///
/// Cupertino n'a pas d'équivalent du SnackBar : sur iOS, un retour transitoire
/// se présente en bannière flottante. On la dessine donc, dans le vocabulaire
/// visuel de l'application. Un passage de niveau se voit plus longtemps.
void showXpFeedback(BuildContext context, AppData data, XpEvent? event) {
  if (event == null || event.xpDelta == 0) return;
  if (!context.mounted) return;

  // Un passage de palier mérite mieux qu'une bannière qui file en une seconde
  // et demie : on s'arrête dessus, et c'est là que la récompense se dévoile.
  if (event.anyLevelUp) {
    _banniereCourante?.remove();
    _banniereCourante = null;
    showLevelUpCelebration(context, data, event);
    return;
  }

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final categorie = data.categoryById(event.categoryId);
  final gain = event.xpDelta > 0;

  final (emoji, texte, teinte) = gain
      ? (
          '✨',
          '+${event.xpDelta} XP · ${categorie?.name ?? ''}',
          AppTheme.success,
        )
      : ('↩︎', '${event.xpDelta} XP repris', AppTheme.missed);

  _banniereCourante?.remove();

  late final OverlayEntry entree;
  entree = OverlayEntry(
    builder: (contexte) => _XpBanner(
      emoji: emoji,
      text: texte,
      tint: teinte,
      lifetime: const Duration(milliseconds: 1500),
      onFinished: () {
        if (_banniereCourante == entree) {
          entree.remove();
          _banniereCourante = null;
        }
      },
    ),
  );
  _banniereCourante = entree;
  overlay.insert(entree);
}

/// Bannière flottante qui descend du haut, comme une notification iOS.
///
/// Toute sa vie — entrée, maintien, sortie — tient dans un seul contrôleur
/// d'animation plutôt que dans une minuterie détachée : la bannière se retire
/// donc d'elle-même, et un test qui laisse tourner les animations la voit
/// disparaître sans laisser de minuterie en suspens.
class _XpBanner extends StatefulWidget {
  const _XpBanner({
    required this.emoji,
    required this.text,
    required this.tint,
    required this.lifetime,
    required this.onFinished,
  });

  final String emoji;
  final String text;
  final Color tint;

  /// Passage de niveau : bannière teintée et plus affirmée.

  /// Durée totale, entrée et sortie comprises.
  final Duration lifetime;

  final VoidCallback onFinished;

  @override
  State<_XpBanner> createState() => _XpBannerState();
}

class _XpBannerState extends State<_XpBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;
  late final Animation<double> _apparition;

  @override
  void initState() {
    super.initState();
    _controleur = AnimationController(vsync: this, duration: widget.lifetime);

    // Part de 0, monte à 1 le temps d'entrer, s'y maintient, puis redescend.
    final entree = widget.lifetime.inMilliseconds == 0
        ? 1.0
        : 260 / widget.lifetime.inMilliseconds;
    _apparition = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: entree,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: (1 - entree * 2).clamp(0.0, 1.0),
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: entree,
      ),
    ]).animate(_controleur);

    _controleur
      ..addStatusListener((statut) {
        if (statut == AnimationStatus.completed) widget.onFinished();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hautSur = MediaQuery.paddingOf(context).top;
    final fond = c.card;
    final label = c.label;

    return Positioned(
      top: hautSur + 8,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _apparition,
        builder: (contexte, enfant) {
          final t = _apparition.value;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * -24),
              child: enfant,
            ),
          );
        },
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fond,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.tint.withValues(alpha: 0.4),
                width: 0.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.emoji, style: AppText.emoji(17)),
                Gaps.w12,
                Flexible(
                  child: Text(
                    widget.text,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(label, size: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
