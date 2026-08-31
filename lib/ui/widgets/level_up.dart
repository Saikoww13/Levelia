import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/app_data.dart';
import '../../domain/models/reward.dart';
import '../../state/app_controller.dart';

/// Une branche qui vient de franchir un palier.
class LevelUp {
  const LevelUp({
    required this.branchName,
    required this.level,
    required this.gained,
    required this.color,
  });

  final String branchName;
  final int level;

  /// Nombre de paliers franchis d'un coup.
  final int gained;
  final Color color;
}

/// Les montées de niveau contenues dans un événement d'XP.
///
/// La branche du domaine passe devant celle du tronc : c'est l'effort qu'on
/// vient de fournir, donc celui qu'on a envie de voir salué en premier.
List<LevelUp> levelUpsOf(AppData data, XpEvent event) {
  final categorie = data.categoryById(event.categoryId);
  return [
    if (event.leveledUp)
      LevelUp(
        branchName: categorie?.name ?? 'Domaine',
        level: event.newLevel,
        gained: event.newLevel - event.previousLevel,
        color: categorie?.color ?? AppTheme.seed,
      ),
    if (event.globalLeveledUp)
      LevelUp(
        branchName: 'Global',
        level: event.globalLevel,
        gained: event.globalLevel - event.previousGlobalLevel,
        color: AppTheme.seed,
      ),
  ];
}

/// Phrase d'encouragement associée à un niveau.
///
/// Choisie par le niveau plutôt qu'au hasard : deux passages du même palier
/// disent la même chose, ce qui rend l'écran testable et évite qu'une même
/// phrase tombe deux fois de suite.
String encouragementFor(int level) {
  const phrases = [
    'Tu tiens le cap. Continue comme ça.',
    'La régularité paie. Ne lâche rien.',
    'Beau travail — le prochain palier est déjà en vue.',
    'C\'est exactement comme ça qu\'on progresse.',
    'Tu construis quelque chose. Garde le rythme.',
  ];
  return phrases[level % phrases.length];
}

/// Présente la célébration d'un passage de niveau.
///
/// Renvoie une fois la carte refermée, pour que l'appelant puisse enchaîner.
Future<void> showLevelUpCelebration(
  BuildContext context,
  AppData data,
  XpEvent event,
) {
  final montees = levelUpsOf(data, event);
  if (montees.isEmpty) return Future.value();

  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (contexte) =>
        _LevelUpCard(levelUps: montees, rewards: event.unlocked),
  );
}

/// La carte de célébration : éclat, médaillon, encouragement, récompenses.
class _LevelUpCard extends StatefulWidget {
  const _LevelUpCard({required this.levelUps, required this.rewards});

  final List<LevelUp> levelUps;
  final List<Reward> rewards;

  @override
  State<_LevelUpCard> createState() => _LevelUpCardState();
}

class _LevelUpCardState extends State<_LevelUpCard>
    with SingleTickerProviderStateMixin {
  /// Toute l'animation tient dans un contrôleur unique découpé en intervalles.
  ///
  /// Aucune minuterie détachée : la carte s'anime une fois puis se tait, ce
  /// qui permet à un test de la laisser se stabiliser sans rester bloqué.
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final principale = widget.levelUps.first;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (contexte, _) {
        final entree = const Interval(
          0,
          0.35,
          curve: Curves.easeOutBack,
        ).transform(_ctrl.value);
        final eclat = const Interval(
          0.1,
          0.75,
          curve: Curves.easeOut,
        ).transform(_ctrl.value);
        final revele = const Interval(
          0.45,
          1,
          curve: Curves.easeOut,
        ).transform(_ctrl.value);

        return Center(
          child: Opacity(
            opacity: entree.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.86 + 0.14 * entree,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(
                      AppTheme.cardRadius + 6,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Medaillon(levelUp: principale, burst: eclat),
                      Gaps.h16,
                      Text(
                        'Niveau ${principale.level}',
                        style: AppText.readout(size: 34, color: c.label),
                      ),
                      Gaps.h4,
                      Text(
                        principale.gained > 1
                            ? '${principale.branchName} · '
                                  '${principale.gained} paliers d\'un coup'
                            : principale.branchName,
                        style: AppText.caption(c.secondary),
                      ),
                      if (widget.levelUps.length > 1) ...[
                        Gaps.h8,
                        _AutreMontee(levelUp: widget.levelUps[1]),
                      ],
                      Gaps.h16,
                      Text(
                        encouragementFor(principale.level),
                        textAlign: TextAlign.center,
                        style: AppText.body(c.label),
                      ),
                      if (widget.rewards.isNotEmpty)
                        Opacity(
                          opacity: revele.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - revele)),
                            child: _Recompenses(rewards: widget.rewards),
                          ),
                        ),
                      Gaps.h8,
                      CupertinoButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Continuer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Le disque du niveau, entouré de son éclat.
class _Medaillon extends StatelessWidget {
  const _Medaillon({required this.levelUp, required this.burst});

  final LevelUp levelUp;
  final double burst;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: CustomPaint(
        painter: _BurstPainter(t: burst, color: levelUp.color),
        child: Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: levelUp.color.withValues(alpha: 0.16),
              border: Border.all(color: levelUp.color, width: 2.5),
            ),
            child: Center(
              child: Text(
                '${levelUp.level}',
                style: AppText.readout(size: 34, color: levelUp.color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rayons qui jaillissent puis s'effacent.
class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.t, required this.color});

  /// Avancement de l'éclat, entre 0 et 1.
  final double t;
  final Color color;

  static const int _rayons = 14;

  /// Rayon du disque central, que les traits doivent contourner.
  static const double _rayonMedaillon = 42;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;

    final centre = size.center(Offset.zero);
    final portee = size.width / 2;

    // Les rayons naissent au ras du médaillon et filent vers le bord. Partir
    // de plus près les cacherait sous le disque : c'est le rayon du
    // médaillon, et non celui de la zone, qui fixe leur origine.
    final debut = _rayonMedaillon + (portee - _rayonMedaillon) * 0.3 * t;
    final fin = debut + (portee - _rayonMedaillon) * 0.6;

    // Intensité en cloche : les rayons éclosent puis s'éteignent, au lieu de
    // surgir à pleine force sur une carte encore transparente.
    final trait = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: math.sin(math.pi * t) * 0.9);

    for (var i = 0; i < _rayons; i++) {
      // Une légère rotation accompagne la poussée : les rayons s'ouvrent en
      // éventail au lieu de gicler tout droit.
      final angle = i * 2 * math.pi / _rayons + t * 0.25;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        centre + direction * debut,
        centre + direction * fin,
        trait,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}

/// Ligne de la seconde branche qui a monté, s'il y en a une.
class _AutreMontee extends StatelessWidget {
  const _AutreMontee({required this.levelUp});

  final LevelUp levelUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: levelUp.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${levelUp.branchName} passe niveau ${levelUp.level}',
        style: AppText.caption(levelUp.color),
      ),
    );
  }
}

/// Les récompenses que ce passage vient de débloquer.
class _Recompenses extends StatelessWidget {
  const _Recompenses({required this.rewards});

  final List<Reward> rewards;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      children: [
        Gaps.h16,
        Text(
          rewards.length > 1 ? 'TES RÉCOMPENSES' : 'TA RÉCOMPENSE',
          style: AppText.unit(AppTheme.streak, size: 11),
        ),
        Gaps.h8,
        for (final r in rewards)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.streak.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.rosette,
                  size: 17,
                  color: AppTheme.streak,
                ),
                Gaps.w8,
                Expanded(
                  child: Text(
                    r.title,
                    style: AppText.body(
                      c.label,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Retrouve-la dans l\'arbre pour la marquer comme savourée.',
          textAlign: TextAlign.center,
          style: AppText.caption(c.tertiary),
        ),
      ],
    );
  }
}
