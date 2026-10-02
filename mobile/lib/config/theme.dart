import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DIRTY GARAGE palette — §2.1 of `spec/design-preview/dirty-garage-proposal.md`.
///
/// Hard rules that come with these tokens:
///  * no pure black, no pure white — the black is brownish, the white yellowed;
///  * [rustRed] is a FILL ONLY colour. As text on dark it scores 2.61:1 and is
///    forbidden; the "ZALEGŁE" state always appears as a stamp (bone on rust);
///  * [oxideOrange] never carries small text (3.94:1) — [oxideLit] does;
///  * [militaryOlive] never carries text (2.64:1) — [oliveLit] does.
class AppColors {
  AppColors._();

  /// App canvas.
  static const Color oilBlack = Color(0xFF1B1A17);

  /// Recesses: bar tracks, input fields, bottom navigation.
  static const Color grease = Color(0xFF141310);

  /// Card / panel surface.
  static const Color dirtyBlack = Color(0xFF26241F);

  /// Primary text on dark; background of paper cards.
  static const Color agedPaper = Color(0xFFD8C9A7);

  /// Headlines, key numbers, accent frames.
  static const Color bone = Color(0xFFE5D8B8);

  /// Secondary text, captions, units.
  static const Color fadedInk = Color(0xFF98907E);

  /// Structural borders (1.5 px).
  static const Color steel = Color(0xFF74746D);

  /// Thin dividers, table grids.
  static const Color hairline = Color(0xFF3A382F);

  /// FILL ONLY: overdue stamps, critical bar.
  static const Color rustRed = Color(0xFF9E3D28);

  /// Primary button fill, "TERMIN" bar fill.
  static const Color oxideOrange = Color(0xFFC05A32);

  /// Same role as [oxideOrange] but as text/icon on dark.
  static const Color oxideLit = Color(0xFFD9743F);

  /// KONTROLA state, hazard stripes, text on dark.
  static const Color dirtyYellow = Color(0xFFC9A33B);

  /// OK state fill.
  static const Color militaryOlive = Color(0xFF596044);

  /// OK state as text on dark.
  static const Color oliveLit = Color(0xFF8B9663);

  // --- derived, still from §2.2 / §4 -----------------------------------------

  /// Hard shadow ink (§4).
  static const Color shadowInk = Color(0xFF0E0D0B);

  /// Dark olive used as ink on paper (6.10:1).
  static const Color oliveInk = Color(0xFF3F4530);

  /// Ink on paper cards (10.63:1).
  static const Color paperInk = oilBlack;

  /// Secondary ink on paper cards.
  static const Color paperInkFaded = Color(0xFF6B6453);

  /// Hairline on paper cards.
  static const Color paperHairline = Color(0xFFA89A7B);

  /// Binder strip on paper cards.
  static const Color paperBinding = Color(0xFFC9B994);

  /// Dotted leader colour on dark panels.
  static const Color leaderDot = Color(0xFF4A4840);
}

/// Three typefaces, three disjoint roles — §3. Never mixed:
///  * Barlow Condensed — headings, labels, buttons, stamps. ALWAYS uppercase,
///    never for running text (max ~4 words).
///  * IBM Plex Mono — every number and technical value, tabular figures.
///  * Barlow — prose: notes, descriptions, error messages. Never uppercase.
class AppText {
  AppText._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// DISPLAY 44–56 · Barlow Condensed 900 — vehicle model, wordmark.
  static TextStyle display({double size = 46, Color color = AppColors.bone}) =>
      GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 0.9,
        letterSpacing: size * 0.01,
        color: color,
      );

  /// H1 30–34 · Barlow Condensed 800 — screen title.
  static TextStyle h1({double size = 32, Color color = AppColors.bone}) =>
      GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 0.96,
        letterSpacing: size * 0.015,
        color: color,
      );

  /// H2 20–22 · Barlow Condensed 700 — section headings.
  static TextStyle h2({double size = 20, Color color = AppColors.bone}) =>
      GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: size * 0.04,
        color: color,
      );

  /// Barlow Condensed 800, mid size — card titles, service entry names.
  static TextStyle condensed({
    double size = 21,
    Color color = AppColors.agedPaper,
    FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: weight,
        height: 1.05,
        letterSpacing: size * 0.03,
        color: color,
      );

  /// LABEL 10–11 · IBM Plex Mono 600 UPPERCASE ls .14em.
  static TextStyle label({double size = 10.5, Color color = AppColors.fadedInk}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: size * 0.14,
        color: color,
      );

  /// DATA-XL 34–58 · IBM Plex Mono 600 — odometer, gauge percentage.
  static TextStyle dataXl({double size = 44, Color color = AppColors.bone}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 0.95,
        color: color,
        fontFeatures: _tabular,
      );

  /// DATA 13–15 · IBM Plex Mono 500 — table values, costs, dates.
  static TextStyle data({
    double size = 13,
    Color color = AppColors.bone,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: size * 0.04,
        color: color,
        fontFeatures: _tabular,
      );

  /// BODY 14–15 · Barlow 400, line height 1.45 — never uppercase.
  static TextStyle body({double size = 14, Color color = AppColors.agedPaper}) =>
      GoogleFonts.barlow(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  /// MICRO 9–10 · IBM Plex Mono 500 UPPERCASE — entry numbers, form codes.
  static TextStyle micro({double size = 9.5, Color color = AppColors.fadedInk}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: size * 0.16,
        color: color,
      );

  /// BUTTON 14–16 · Barlow Condensed 800 UPPERCASE ls .06–.08em.
  static TextStyle button({double size = 16, Color color = AppColors.grease}) =>
      GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.08,
        color: color,
      );

  /// Stamp face — Barlow Condensed 800, heavy tracking.
  static TextStyle stamp({double size = 10.5, required Color color}) =>
      GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: size * 0.14,
        color: color,
      );
}

/// Geometry tokens — §4. Zero radius everywhere, hard offset shadows only,
/// never blurred, never soft.
class AppGeo {
  AppGeo._();

  static const double radius = 0;

  static const BorderSide structure =
      BorderSide(color: AppColors.steel, width: 1.5);
  static const BorderSide emphasis =
      BorderSide(color: AppColors.bone, width: 2);
  static const BorderSide hair =
      BorderSide(color: AppColors.hairline, width: 1);

  /// `4px 4px 0` — cards, buttons, stamps.
  static const List<BoxShadow> shadowHard = [
    BoxShadow(color: AppColors.shadowInk, offset: Offset(4, 4)),
  ];

  /// `2px 2px 0` — chips, small plaques, pressed state.
  static const List<BoxShadow> shadowHardSm = [
    BoxShadow(color: AppColors.shadowInk, offset: Offset(2, 2)),
  ];

  /// `4px 4px 0 #1B1A17` — paper cards on the dark canvas.
  static const List<BoxShadow> shadowPaper = [
    BoxShadow(color: AppColors.oilBlack, offset: Offset(4, 4)),
  ];

  /// 4 px base grid.
  static const double screenMargin = 20;
  static const double cardGap = 14;
  static const double sectionGap = 28;
  static const double minTouch = 48;

  /// Press animation length for the "button falls into its housing" state.
  static const Duration pressDuration = Duration(milliseconds: 90);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      surface: AppColors.dirtyBlack,
      onSurface: AppColors.agedPaper,
      surfaceContainerHighest: AppColors.grease,
      primary: AppColors.oxideOrange,
      onPrimary: AppColors.grease,
      secondary: AppColors.oxideLit,
      onSecondary: AppColors.grease,
      tertiary: AppColors.dirtyYellow,
      error: AppColors.oxideLit,
      onError: AppColors.grease,
      outline: AppColors.steel,
      outlineVariant: AppColors.hairline,
      shadow: AppColors.shadowInk,
    );

    const squareBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    );

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.oilBlack,
      canvasColor: AppColors.oilBlack,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.agedPaper, size: 20),
      textTheme: TextTheme(
        displayLarge: AppText.display(),
        headlineLarge: AppText.h1(),
        headlineMedium: AppText.h1(size: 28),
        titleLarge: AppText.h2(),
        titleMedium: AppText.condensed(size: 18),
        labelLarge: AppText.button(color: AppColors.bone),
        labelSmall: AppText.label(),
        bodyLarge: AppText.body(size: 15),
        bodyMedium: AppText.body(),
        bodySmall: AppText.micro(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.oilBlack,
        foregroundColor: AppColors.bone,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppGeo.screenMargin,
        toolbarHeight: 56,
        iconTheme: const IconThemeData(color: AppColors.agedPaper, size: 21),
        actionsIconTheme:
            const IconThemeData(color: AppColors.agedPaper, size: 20),
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.9,
          color: AppColors.bone,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.dirtyBlack,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: AppGeo.structure,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grease,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: AppText.data(size: 14, color: AppColors.steel),
        labelStyle: AppText.label(),
        floatingLabelStyle: AppText.label(color: AppColors.dirtyYellow),
        errorStyle: AppText.body(size: 12.5, color: AppColors.oxideLit),
        border: inputBorder(AppColors.steel, 1.5),
        enabledBorder: inputBorder(AppColors.steel, 1.5),
        disabledBorder: inputBorder(AppColors.hairline, 1.5),
        focusedBorder: inputBorder(AppColors.dirtyYellow, 2),
        errorBorder: inputBorder(AppColors.oxideLit, 1.5),
        focusedErrorBorder: inputBorder(AppColors.oxideLit, 2),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.dirtyYellow,
        selectionColor: Color(0x55C9A33B),
        selectionHandleColor: AppColors.dirtyYellow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.oxideOrange,
          foregroundColor: AppColors.grease,
          disabledBackgroundColor: AppColors.hairline,
          disabledForegroundColor: AppColors.fadedInk,
          elevation: 0,
          minimumSize: const Size(0, AppGeo.minTouch),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: AppGeo.emphasis,
          ),
          textStyle: AppText.button(size: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.agedPaper,
          side: AppGeo.structure,
          elevation: 0,
          minimumSize: const Size(0, AppGeo.minTouch),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: squareBorder,
          textStyle: AppText.button(size: 14.5, color: AppColors.agedPaper),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.agedPaper,
          shape: squareBorder,
          minimumSize: const Size(0, AppGeo.minTouch),
          textStyle: AppText.button(size: 14.5, color: AppColors.agedPaper),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.oxideOrange
                : AppColors.grease,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.grease
                : AppColors.fadedInk,
          ),
          side: WidgetStateProperty.all(AppGeo.structure),
          shape: WidgetStateProperty.all(squareBorder),
          textStyle: WidgetStateProperty.all(AppText.button(size: 13)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.oxideLit,
        linearTrackColor: AppColors.grease,
        circularTrackColor: AppColors.grease,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: AppColors.dirtyBlack,
        actionTextColor: AppColors.oxideLit,
        contentTextStyle: AppText.body(size: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: AppGeo.structure,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dirtyBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: AppGeo.structure,
        ),
        titleTextStyle: AppText.h2(),
        contentTextStyle: AppText.body(),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.dirtyBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: AppGeo.structure,
        ),
        headerBackgroundColor: AppColors.grease,
        headerForegroundColor: AppColors.bone,
        dayShape: WidgetStateProperty.all(squareBorder),
        todayBorder: const BorderSide(color: AppColors.dirtyYellow, width: 1.5),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.dirtyBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.oxideOrange,
        foregroundColor: AppColors.grease,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: AppGeo.emphasis,
        ),
      ),
    );
  }
}
