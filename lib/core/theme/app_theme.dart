import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/*
  THESIS: Levelia is a performance log, not a checklist. The daily view reads
  like an athlete's session sheet — domain-coded channels left, earned numbers
  right, progress as a real stat bar. Refuses the illustrated card grid.

  OWN-WORLD: Near-black #07090D ground · #131720 card surface · steel blue
  #3A8FD1 as global stat accent · category colors as domain "team colors" ·
  #4AB588 done/positive · #D05A5A missed/negative · #C8852A streak amber ·
  Barlow Condensed for readout numerals · tight tracking on all data labels.

  FORM: Sports analytics (my pick) · seed 819a8feb
  FINISH: unreviewed and undocumented is unfinished; this build ends with the
  finish review, the verdict, DESIGN.md, and every shipping raster carrying
  its provenance.
*/

class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF3A8FD1);
  static const Color success = Color(0xFF4AB588);
  static const Color missed = Color(0xFFD05A5A);
  static const Color streak = Color(0xFFC8852A);

  // Dark ground anchors
  static const Color _darkGround = Color(0xFF07090D);
  static const Color _darkCard = Color(0xFF131720);
  static const Color _darkNav = Color(0xFF0A0C13);

  // Light ground anchors
  static const Color _lightGround = Color(0xFFF1F3F7);
  static const Color _lightCard = Color(0xFFFFFFFF);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? _darkGround : _lightGround,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.barlow(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? _darkCard : _lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: dark
                ? const Color(0xFF1E2230)
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF0F1219) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.barlow(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(
          color: dark
              ? const Color(0xFF1E2230)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 62,
        backgroundColor: dark ? _darkNav : _lightCard,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.6),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.barlow(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: dark
            ? const Color(0xFF1A1E2A)
            : scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

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
