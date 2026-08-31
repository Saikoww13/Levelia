import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';

/// Page standard de l'application : fond, grande barre de titre iOS qui se
/// replie au défilement, et contenu défilant.
///
/// Toutes les destinations principales passent par ici, ce qui garantit le même
/// comportement de barre partout — c'est ce qui donne à une application son
/// « allure iOS » avant même les couleurs.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
  });

  final String title;

  /// Ligne discrète sous le titre replié (date du jour, par exemple).
  final String? subtitle;

  /// Action de droite dans la barre. Sur iOS, c'est là que vit le « + » —
  /// il n'y a pas de bouton flottant.
  final Widget? trailing;

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final secondaire = c.secondary;

    // La barre d'onglets est translucide : le contenu défile dessous, et
    // Flutter signale la hauteur ainsi masquée — barre plus indicateur
    // d'accueil — dans `MediaQuery.padding`. Sans la reporter au bas de la
    // liste, les derniers éléments restent sous la barre quoi qu'on fasse,
    // puisque le défilement s'arrête avant. En barre latérale, où rien
    // n'obstrue le bas, cette valeur est nulle et la marge ne bouge pas.
    final masque = MediaQuery.paddingOf(context).bottom;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            middle: subtitle == null ? null : Text(title),
            trailing: trailing,
            backgroundColor: c.bar,
            border: Border(bottom: BorderSide(color: c.separator, width: 0.5)),
          ),
          if (subtitle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(subtitle!, style: AppText.caption(secondaire)),
              ),
            ),
          SliverPadding(
            padding: padding.copyWith(bottom: padding.bottom + masque),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(children),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton « + » de barre de navigation, au format iOS.
class NavAddButton extends StatelessWidget {
  const NavAddButton({super.key, required this.onPressed, this.semantic});

  final VoidCallback onPressed;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(36, 36),
      onPressed: onPressed,
      child: Icon(
        CupertinoIcons.add,
        size: 24,
        color: AppTheme.seed,
        semanticLabel: semantic,
      ),
    );
  }
}

/// En-tête de groupe d'une liste iOS : petites capitales grises, calées à
/// gauche au-dessus de la section.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final secondaire = c.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: 'CupertinoSystemText',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: secondaire,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Écran vide expressif : une icône, un message, et de quoi agir.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = c.label;
    final secondaire = c.secondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: c.tertiary),
            Gaps.h16,
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.title(label, size: 17),
            ),
            Gaps.h8,
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.caption(secondaire, size: 14),
            ),
            if (action != null) ...[Gaps.h24, action!],
          ],
        ),
      ),
    );
  }
}

/// Étiquette de groupe d'un formulaire, au-dessus d'un contrôle.
class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final secondaire = c.secondary;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'CupertinoSystemText',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: secondaire,
        ),
      ),
    );
  }
}

/// Carte au format des listes encartées d'iOS.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Teinte de rattachement à une catégorie : voile coloré très léger.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fond = c.card;

    final contenu = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: accent == null
            ? fond
            : Color.alphaBlend(accent!.withValues(alpha: 0.06), fond),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: accent == null ? c.separator : accent!.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (onTap == null) return contenu;

    // Pression atténuée : le retour tactile d'iOS est un fondu, pas une onde.
    return _PressFade(onTap: onTap!, child: contenu);
  }
}

/// Enveloppe tactile façon iOS : le contenu s'atténue tant que le doigt appuie.
class _PressFade extends StatefulWidget {
  const _PressFade({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressFade> createState() => _PressFadeState();
}

class _PressFadeState extends State<_PressFade> {
  bool _enfonce = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _enfonce = true),
      onTapUp: (_) => setState(() => _enfonce = false),
      onTapCancel: () => setState(() => _enfonce = false),
      child: AnimatedOpacity(
        opacity: _enfonce ? 0.6 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// Bloc de statistique : une grande valeur, un libellé.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.icon,
  });

  final String value;
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final teinte = color ?? AppTheme.seed;
    final secondaire = c.secondary;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 17, color: teinte), Gaps.h8],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.readout(size: 26, color: teinte),
          ),
          Gaps.h4,
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption(secondaire, size: 12),
          ),
        ],
      ),
    );
  }
}

/// Anneau de progression déterminé.
///
/// Cupertino n'en fournit pas — son indicateur d'activité ne sait qu'attendre,
/// pas montrer une proportion. On le dessine donc, ce qui permet au passage de
/// caler l'épaisseur et les extrémités arrondies sur le reste de l'interface.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    this.strokeWidth = 6,
    this.child,
  });

  /// Avancement entre 0 et 1.
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          strokeWidth: strokeWidth,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);

    final piste = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: 0.14);
    canvas.drawArc(rect, 0, math.pi * 2, false, piste);

    if (progress <= 0) return;

    final trace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    // On démarre à midi et on tourne dans le sens horaire.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, trace);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
