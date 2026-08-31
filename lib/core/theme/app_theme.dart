import 'package:flutter/cupertino.dart';

/*
  THÈSE : Levelia est un journal de performance, pas une liste de courses.
  L'écran du jour se lit comme la feuille de séance d'un athlète — canaux
  colorés par domaine à gauche, chiffres gagnés à droite, progression en
  barre de stat.

  IDIOME : Apple. Vocabulaire Cupertino de bout en bout (barres de navigation
  à grand titre, listes groupées encartées, feuilles d'action, contrôles
  segmentés glissants). La palette acier et les chiffres condensés restent :
  c'est l'identité de Levelia, pas une convention Android.

  MONDE PROPRE : fond quasi-noir #07090D · surface de carte #131720 · bleu
  acier #3A8FD1 en accent global · couleurs de catégorie comme couleurs
  d'équipe · #4AB588 réussi · #D05A5A manqué · #C8852A série.
*/

/// Palette et jetons visuels de Levelia.
///
/// Chaque couleur qui change entre clair et sombre est un
/// [CupertinoDynamicColor] : elle se résout d'elle-même selon la luminosité
/// ambiante, comme les couleurs système d'iOS.
class AppTheme {
  const AppTheme._();

  // ── Accents (identiques dans les deux modes : ce sont des couleurs de marque)

  /// Accent global : bleu acier.
  static const Color seed = Color(0xFF3A8FD1);

  /// Journée tenue, objectif atteint.
  static const Color success = Color(0xFF4AB588);

  /// Journée manquée, pénalité.
  static const Color missed = Color(0xFFD05A5A);

  /// Séries en cours.
  static const Color streak = Color(0xFFC8852A);

  // ── Fonds et surfaces

  /// Fond de l'application.
  static const CupertinoDynamicColor ground =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFFF1F3F7),
        darkColor: Color(0xFF07090D),
      );

  /// Surface des cartes et des sections de liste.
  static const CupertinoDynamicColor card =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFFFFFFFF),
        darkColor: Color(0xFF131720),
      );

  /// Fond des barres de navigation et de la barre d'onglets.
  static const CupertinoDynamicColor bar = CupertinoDynamicColor.withBrightness(
    color: Color(0xF2FFFFFF),
    darkColor: Color(0xF20A0C13),
  );

  /// Trait de séparation, discret.
  static const CupertinoDynamicColor separator =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFFDDE1E9),
        darkColor: Color(0xFF1E2230),
      );

  /// Fond des champs de saisie.
  static const CupertinoDynamicColor field =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFFFFFFFF),
        darkColor: Color(0xFF0F1219),
      );

  // ── Textes

  /// Texte principal.
  static const CupertinoDynamicColor label =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFF0B0D12),
        darkColor: Color(0xFFF2F4F8),
      );

  /// Texte secondaire : métadonnées, légendes, unités.
  static const CupertinoDynamicColor secondaryLabel =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFF6B7280),
        darkColor: Color(0xFF8A93A6),
      );

  /// Texte très effacé : éléments désactivés.
  static const CupertinoDynamicColor tertiaryLabel =
      CupertinoDynamicColor.withBrightness(
        color: Color(0xFFA6ADBB),
        darkColor: Color(0xFF565E70),
      );

  /// Rayon d'arrondi des cartes et sections, calé sur les listes encartées d'iOS.
  static const double cardRadius = 12;

  /// Le thème Cupertino de l'application pour une luminosité donnée.
  ///
  /// [brightness] à `null` laisse iOS suivre le réglage du système.
  static CupertinoThemeData theme(Brightness? brightness) {
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: seed,
      scaffoldBackgroundColor: ground,
      barBackgroundColor: bar,
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: seed,
        textStyle: TextStyle(
          fontFamily: 'CupertinoSystemText',
          fontSize: 16,
          letterSpacing: -0.2,
          color: label,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: 'CupertinoSystemDisplay',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: label,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: 'CupertinoSystemDisplay',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
          color: label,
        ),
        tabLabelTextStyle: TextStyle(
          fontFamily: 'CupertinoSystemText',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          color: secondaryLabel,
        ),
      ),
    );
  }
}

/// Les couleurs du thème, déjà résolues pour la luminosité ambiante.
///
/// Sans cela, chaque widget appelle `CupertinoDynamicColor.resolve` pour
/// chaque teinte dont il a besoin : la même cérémonie de quatre lignes,
/// répétée des dizaines de fois, qui noie l'intention dans le bruit. Ici, une
/// seule ligne en tête de `build` donne accès à toute la palette.
///
/// ```dart
/// final c = AppColors.of(context);
/// Text('Bonjour', style: AppText.title(c.label));
/// ```
class AppColors {
  const AppColors._({
    required this.label,
    required this.secondary,
    required this.tertiary,
    required this.card,
    required this.field,
    required this.separator,
    required this.bar,
    required this.ground,
  });

  /// Résout la palette pour le contexte donné.
  factory AppColors.of(BuildContext context) {
    Color resoudre(CupertinoDynamicColor couleur) =>
        CupertinoDynamicColor.resolve(couleur, context);

    return AppColors._(
      label: resoudre(AppTheme.label),
      secondary: resoudre(AppTheme.secondaryLabel),
      tertiary: resoudre(AppTheme.tertiaryLabel),
      card: resoudre(AppTheme.card),
      field: resoudre(AppTheme.field),
      separator: resoudre(AppTheme.separator),
      bar: resoudre(AppTheme.bar),
      ground: resoudre(AppTheme.ground),
    );
  }

  /// Texte principal.
  final Color label;

  /// Texte secondaire : métadonnées, légendes, unités.
  final Color secondary;

  /// Texte très effacé : éléments désactivés.
  final Color tertiary;

  /// Surface des cartes.
  final Color card;

  /// Fond des champs de saisie.
  final Color field;

  /// Trait de séparation.
  final Color separator;

  /// Fond des barres de navigation.
  final Color bar;

  /// Fond de l'application.
  final Color ground;
}

/// Styles de texte de l'application.
///
/// Le texte courant utilise la police système (SF Pro) : c'est ce qui fait
/// qu'une application « sonne » Apple. Seuls les relevés chiffrés gardent
/// Barlow Condensed, qui est une signature de Levelia et non une convention
/// de plateforme.
class AppText {
  const AppText._();

  /// Famille empaquetée dans `assets/fonts`, déclarée sous ce nom dans
  /// `pubspec.yaml`. Les graisses disponibles sont 500, 600 et 700 : demander
  /// une graisse absente ferait synthétiser un faux gras par le moteur.
  static const String _condensed = 'BarlowCondensed';

  /// Chiffre de relevé : XP, niveau, compteur. Chasse fixe pour que les
  /// nombres ne dansent pas quand ils changent.
  static TextStyle readout({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: _condensed,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.0,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Étiquette d'unité ou de colonne, en petites capitales espacées.
  static TextStyle unit(Color color, {double size = 10}) {
    return TextStyle(
      fontFamily: _condensed,
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.8,
      height: 1.0,
    );
  }

  /// Style d'un texte purement emoji.
  ///
  /// Nomme explicitement la police emoji de chaque plateforme en repli. Sans
  /// cela, le texte hérite de la police du thème, qui ne contient aucun
  /// glyphe emoji : si la chaîne de repli du système ne prend pas le relais,
  /// on obtient des carrés. Nommer les polices retire cette incertitude.
  static TextStyle emoji(double size) => TextStyle(
    fontSize: size,
    fontFamilyFallback: const [
      'Apple Color Emoji',
      'Noto Color Emoji',
      'Segoe UI Emoji',
    ],
  );

  /// Titre de contenu (nom d'habitude, d'objectif, de domaine).
  static TextStyle title(Color color, {double size = 16}) => TextStyle(
    fontFamily: 'CupertinoSystemText',
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: color,
  );

  /// Texte courant.
  static TextStyle body(Color color, {double size = 15}) => TextStyle(
    fontFamily: 'CupertinoSystemText',
    fontSize: size,
    letterSpacing: -0.2,
    color: color,
  );

  /// Métadonnée discrète sous un titre.
  static TextStyle caption(Color color, {double size = 13}) => TextStyle(
    fontFamily: 'CupertinoSystemText',
    fontSize: size,
    letterSpacing: -0.1,
    color: color,
  );

  /// En-tête de groupe d'une liste encartée : petites capitales grises.
  static TextStyle groupHeader(Color color) => TextStyle(
    fontFamily: 'CupertinoSystemText',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    color: color,
  );
}

/// Espacements standard, pour garder un rythme vertical cohérent.
class Gaps {
  const Gaps._();

  static const Widget h4 = SizedBox(height: 4);
  static const Widget h8 = SizedBox(height: 8);
  static const Widget h12 = SizedBox(height: 12);
  static const Widget h16 = SizedBox(height: 16);
  static const Widget h24 = SizedBox(height: 24);
  static const Widget h32 = SizedBox(height: 32);

  static const Widget w4 = SizedBox(width: 4);
  static const Widget w8 = SizedBox(width: 8);
  static const Widget w12 = SizedBox(width: 12);
  static const Widget w16 = SizedBox(width: 16);
}
