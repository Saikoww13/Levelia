import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/seed.dart';
import '../../state/providers.dart';
import '../widgets/category_widgets.dart';
import '../widgets/modal_page.dart';

/// Une page d'explication : une icône, un titre, un texte.
class _Slide {
  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

const List<_Slide> _slides = [
  _Slide(
    icon: CupertinoIcons.square_list_fill,
    color: AppTheme.seed,
    title: 'Aujourd\'hui',
    body:
        'Chaque jour, tu retrouves ici ce qui est prévu. Un appui coche une '
        'habitude, un deuxième la marque manquée. L\'XP gagnée s\'affiche '
        'aussitôt.',
  ),
  _Slide(
    icon: CupertinoIcons.checkmark_circle_fill,
    color: AppTheme.success,
    title: 'Habitudes',
    body:
        'Des habitudes à faire, ou à éviter. Tu choisis leur rythme — chaque '
        'jour, certains jours, ou plusieurs fois par semaine — et ce qu\'elles '
        'rapportent quand tu les tiens.',
  ),
  _Slide(
    icon: CupertinoIcons.flag_fill,
    color: AppTheme.streak,
    title: 'Objectifs',
    body:
        'Un objectif donne une direction à tes habitudes. Découpe-le en '
        'étapes : chacune rapporte de l\'XP, et l\'échéance te garde honnête.',
  ),
  _Slide(
    icon: CupertinoIcons.chart_bar_fill,
    color: AppTheme.seed,
    title: 'Progression',
    body:
        'Ta régularité semaine après semaine, tes séries en cours, ton XP jour '
        'après jour. Ce que tu délaisses se voit autant que ce que tu tiens.',
  ),
  _Slide(
    icon: CupertinoIcons.person_fill,
    color: AppTheme.missed,
    title: 'Profil',
    body:
        'Ton niveau global et celui de chaque domaine. Tes données restent sur '
        'cet appareil, et tu peux les exporter quand tu veux.',
  ),
];

/// Introduction affichée au tout premier lancement.
///
/// Sept écrans : un salut, les cinq onglets, puis la création du premier
/// domaine et de la première habitude. « Passer » est disponible partout : une
/// introduction qu'on ne peut pas quitter est une introduction subie.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  /// Nombre total d'écrans : salut + explications + création.
  static const int _total = 1 + 5 + 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _suivant() {
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _passer() =>
      ref.read(appControllerProvider.notifier).completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dernier = _page == _total - 1;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: _passer,
                child: Text(
                  'Passer',
                  style: AppText.body(c.secondary, size: 15),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomePage(),
                  for (final slide in _slides) _SlidePage(slide: slide),
                  const _SetupPage(),
                ],
              ),
            ),
            _Dots(count: _total, current: _page),
            Gaps.h16,
            // Le dernier écran porte sa propre action de validation.
            if (!dernier)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _suivant,
                    child: const Text('Continuer'),
                  ),
                ),
              )
            else
              Gaps.h24,
          ],
        ),
      ),
    );
  }
}

/// Écran d'accueil.
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('⚔️', style: AppText.emoji(64)),
          Gaps.h32,
          Text(
            'Bienvenue dans Levelia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'CupertinoSystemDisplay',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: c.label,
            ),
          ),
          Gaps.h16,
          Text(
            'Tes habitudes du quotidien font monter ton niveau, domaine de vie '
            'par domaine de vie. Rien n\'est offert : chaque point d\'XP '
            'correspond à quelque chose que tu as réellement fait.',
            textAlign: TextAlign.center,
            style: AppText.body(c.secondary, size: 16).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Écran d'explication d'un onglet.
class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: slide.color.withValues(alpha: 0.32)),
            ),
            child: Icon(slide.icon, size: 42, color: slide.color),
          ),
          Gaps.h32,
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'CupertinoSystemDisplay',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: c.label,
            ),
          ),
          Gaps.h16,
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppText.body(c.secondary, size: 16).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Dernier écran : choix des domaines et de la première habitude.
class _SetupPage extends ConsumerStatefulWidget {
  const _SetupPage();

  @override
  ConsumerState<_SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<_SetupPage> {
  final _habitude = TextEditingController();
  final Set<String> _choisis = {};
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _habitude.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _habitude.dispose();
    super.dispose();
  }

  List<SuggestedCategory> get _domaines => [
    for (final s in suggestedCategories)
      if (_choisis.contains(s.name)) s,
  ];

  /// Idées d'habitudes du premier domaine retenu.
  List<String> get _idees {
    if (_domaines.isEmpty) return const [];
    return suggestedHabits[_domaines.first.name] ?? const [];
  }

  bool get _valide => _choisis.isNotEmpty && _habitude.text.trim().isNotEmpty;

  Future<void> _commencer() async {
    setState(() => _enregistrement = true);
    try {
      await ref
          .read(appControllerProvider.notifier)
          .applyOnboarding(categories: _domaines, habitTitle: _habitude.text);
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _enregistrement = false);
      await showNotice(
        context,
        title: 'Enregistrement impossible',
        message:
            'Tes données n\'ont pas pu être écrites sur l\'appareil.\n\n$erreur',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      children: [
        Text(
          'On commence',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'CupertinoSystemDisplay',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: c.label,
          ),
        ),
        Gaps.h8,
        Text(
          'Choisis un ou plusieurs domaines à faire progresser. Tu pourras les '
          'renommer, en ajouter et en supprimer à tout moment.',
          textAlign: TextAlign.center,
          style: AppText.caption(c.secondary, size: 14).copyWith(height: 1.4),
        ),
        Gaps.h24,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final suggestion in suggestedCategories)
              CategoryPill(
                label: suggestion.name,
                emoji: suggestion.emoji,
                color: Color(suggestion.colorValue),
                selected: _choisis.contains(suggestion.name),
                background: c.field,
                onTap: () => setState(() {
                  if (!_choisis.remove(suggestion.name)) {
                    _choisis.add(suggestion.name);
                  }
                }),
              ),
          ],
        ),

        Gaps.h32,
        Text(
          'Et une première habitude',
          textAlign: TextAlign.center,
          style: AppText.title(c.label, size: 17),
        ),
        Gaps.h8,
        Text(
          _choisis.isEmpty
              ? 'Choisis d\'abord un domaine ci-dessus.'
              : 'Elle ira dans « ${_domaines.first.name} ».',
          textAlign: TextAlign.center,
          style: AppText.caption(c.secondary, size: 13),
        ),
        Gaps.h12,
        AppTextField(controller: _habitude, placeholder: 'Ex. : lire 10 pages'),
        if (_idees.isNotEmpty) ...[
          Gaps.h12,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final idee in _idees)
                CategoryPill(
                  label: idee,
                  color: AppTheme.seed,
                  selected: _habitude.text.trim() == idee,
                  background: c.field,
                  onTap: () => _habitude.text = idee,
                ),
            ],
          ),
        ],

        Gaps.h32,
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: _valide && !_enregistrement ? _commencer : null,
            child: const Text('Commencer'),
          ),
        ),
        Gaps.h8,
      ],
    );
  }
}

/// Points de progression sous les pages.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == current ? AppTheme.seed : c.separator,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
