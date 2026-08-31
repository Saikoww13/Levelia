import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/engine/skill_tree.dart';
import '../widgets/common.dart';

/// Rayon d'un nœud de l'arbre.
const double _rayon = 15;

/// Hauteur d'une rangée : un nœud et son étiquette.
const double _hauteurRangee = 62;

/// Décalages horizontaux successifs des nœuds, en pixels.
///
/// La tige ne descend pas droit : elle ondule légèrement, ce qui la fait lire
/// comme une branche plutôt que comme une liste à puces.
const List<double> _ondulation = [0, 14, 22, 14];

double _decalage(int index) => _ondulation[index % _ondulation.length];

/// Une branche dessinée : la tige et ses paliers.
///
/// Chaque rangée peint sa propre moitié haute et sa moitié basse de tige, si
/// bien que le trait reste continu sans qu'aucun widget n'ait besoin de
/// connaître la géométrie de toute la branche.
class BranchPath extends StatelessWidget {
  const BranchPath({super.key, required this.branch, required this.onTapNode});

  final SkillBranch branch;
  final void Function(SkillNode node) onTapNode;

  @override
  Widget build(BuildContext context) {
    final couleur = Color(branch.colorValue);

    return Column(
      children: [
        for (var i = 0; i < branch.nodes.length; i++)
          _Rangee(
            node: branch.nodes[i],
            color: couleur,
            previous: i == 0 ? null : _decalage(i - 1),
            offset: _decalage(i),
            next: i == branch.nodes.length - 1 ? null : _decalage(i + 1),
            // La tige au-dessus d'un palier atteint est parcourue ; celle qui
            // mène au palier courant ne l'est qu'à moitié.
            reached: branch.nodes[i].state != NodeState.locked,
            onTap: () => onTapNode(branch.nodes[i]),
          ),
      ],
    );
  }
}

class _Rangee extends StatelessWidget {
  const _Rangee({
    required this.node,
    required this.color,
    required this.previous,
    required this.offset,
    required this.next,
    required this.reached,
    required this.onTap,
  });

  final SkillNode node;
  final Color color;
  final double? previous;
  final double offset;
  final double? next;
  final bool reached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: _hauteurRangee,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _ondulation.reduce(math.max) + _rayon * 2,
              // Position absolue plutôt qu'un alignement relatif : le peintre
              // place le trait à `offset + _rayon`, et le nœud doit tomber
              // exactement là, sinon la tige ne rejoint pas les pastilles.
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _StemPainter(
                        previous: previous,
                        offset: offset,
                        next: next,
                        color: color,
                        idle: c.separator,
                        reached: reached,
                      ),
                    ),
                  ),
                  Positioned(
                    left: offset,
                    top: (_hauteurRangee - _rayon * 2) / 2,
                    child: _Node(node: node, color: color, ground: c.card),
                  ),
                ],
              ),
            ),
            Gaps.w12,
            Expanded(
              child: _Etiquette(node: node, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le trait qui relie les paliers.
class _StemPainter extends CustomPainter {
  const _StemPainter({
    required this.previous,
    required this.offset,
    required this.next,
    required this.color,
    required this.idle,
    required this.reached,
  });

  final double? previous;
  final double offset;
  final double? next;
  final Color color;
  final Color idle;
  final bool reached;

  double _x(double decalage) => decalage + _rayon;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(_x(offset), size.height / 2);
    final trait = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (previous != null) {
      // La moitié haute prend la couleur du palier vers lequel elle mène.
      trait.color = reached ? color.withValues(alpha: 0.45) : idle;
      canvas.drawLine(Offset(_x(previous!), 0), centre, trait);
    }
    if (next != null) {
      trait.color = idle;
      canvas.drawLine(centre, Offset(_x(next!), size.height), trait);
    }
  }

  @override
  bool shouldRepaint(_StemPainter old) =>
      old.previous != previous ||
      old.offset != offset ||
      old.next != next ||
      old.color != color ||
      old.idle != idle ||
      old.reached != reached;
}

/// La pastille d'un palier.
class _Node extends StatelessWidget {
  const _Node({required this.node, required this.color, required this.ground});

  final SkillNode node;
  final Color color;
  final Color ground;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final atteint = node.state == NodeState.reached;
    final courant = node.state == NodeState.current;

    return SizedBox(
      width: _rayon * 2,
      height: _rayon * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Le palier courant porte l'anneau d'avancement : on voit d'un coup
          // d'œil ce qu'il reste à parcourir avant la prochaine récompense.
          if (courant)
            ProgressRing(
              progress: node.progress,
              color: color,
              size: _rayon * 2,
              strokeWidth: 3,
            ),
          Container(
            width: courant ? _rayon * 1.3 : _rayon * 2,
            height: courant ? _rayon * 1.3 : _rayon * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: atteint ? color : ground,
              border: atteint || courant
                  ? null
                  : Border.all(color: c.separator, width: 2),
            ),
            child: atteint
                ? Icon(
                    node.hasReward
                        ? CupertinoIcons.rosette
                        : CupertinoIcons.check_mark,
                    size: node.hasReward ? 14 : 16,
                    color: const Color(0xFFFFFFFF),
                  )
                : node.hasReward && !courant
                ? Icon(CupertinoIcons.rosette, size: 15, color: c.tertiary)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Le texte à droite d'un palier.
class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.node, required this.color});

  final SkillNode node;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final recompense = node.reward;

    if (recompense == null) {
      return Row(
        children: [
          Text('Niveau ${node.level}', style: AppText.body(c.secondary)),
          if (node.state == NodeState.current) ...[
            Gaps.w8,
            Text('· en cours', style: AppText.caption(c.tertiary)),
          ],
        ],
      );
    }

    final atteint = node.state == NodeState.reached;
    final savouree = recompense.claimed;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'NIV ${node.level}',
              style: AppText.unit(atteint ? color : c.tertiary, size: 11),
            ),
            if (atteint && !savouree) ...[
              Gaps.w8,
              _Pastille(text: 'à savourer', color: color),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          recompense.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(atteint ? c.label : c.secondary).copyWith(
            fontWeight: atteint && !savouree
                ? FontWeight.w600
                : FontWeight.w400,
            decoration: savouree ? TextDecoration.lineThrough : null,
            color: savouree ? c.tertiary : null,
          ),
        ),
      ],
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text.toUpperCase(), style: AppText.unit(color, size: 9)),
    );
  }
}
