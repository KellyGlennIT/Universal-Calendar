import 'package:flutter/material.dart';

/// Builds the app's dark Material 3 theme.
///
/// Extracted from `UniversalCalendarApp._darkTheme()` so it can be imported
/// from other files (e.g. in a preview harness or test) without instantiating
/// the whole app widget tree.
///
/// Every sub-theme is set so that any Material widget that appears anywhere
/// in the app — dialogs, snackbars, bottom sheets, popups, chips, dividers,
/// tooltips, progress indicators, list tiles — shares a single visual
/// language without per-widget styling.
ThemeData buildDarkTheme() {
  const primary = Color(0xFF8B82FF);
  const secondary = Color(0xFF63C7C2);
  const surface = Color(0xFF171D2B);
  const cardBg = Color(0xFF1A1F2E);
  const popupBg = Color(0xFF242B3B);
  const scaffoldBg = Color(0xFF0A0E17);
  const mutedText = Color(0xFFB0B0C0);
  const dimText = Color(0xFF707080);
  const hintText = Color(0xFF4A4A5A);
  const subtleBorder = Color(0x14FFFFFF);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: scaffoldBg,
    canvasColor: scaffoldBg,
    cardColor: cardBg,
    dividerColor: subtleBorder,
    disabledColor: const Color(0x4DFFFFFF),
    splashFactory: InkRipple.splashFactory,

    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      surfaceContainerHighest: popupBg,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),

    // ── AppBar ────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),

    // ── Text ──────────────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5),
      displayMedium: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2),
      titleLarge: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(
          color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: mutedText, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: dimText, fontSize: 12, height: 1.3),
      labelLarge: TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(
          color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(
          color: dimText, fontSize: 10, letterSpacing: 0.5),
    ),

    // ── Text fields ───────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      filled: true,
      fillColor: cardBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: hintText),
      labelStyle: const TextStyle(color: mutedText),
      floatingLabelStyle: const TextStyle(color: primary),
    ),

    // ── Cards ─────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
    ),

    // ── Dialogs ───────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      titleTextStyle: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: const TextStyle(
          color: mutedText, fontSize: 14, height: 1.5),
    ),

    // ── Bottom sheets ─────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: cardBg,
      modalBackgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: hintText,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // ── Snackbars ─────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: popupBg,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    ),

    // ── Popup menus ───────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: popupBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    ),

    // ── Chips ─────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: cardBg,
      selectedColor: primary.withValues(alpha: 0.22),
      disabledColor: surface,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      secondaryLabelStyle: const TextStyle(
          color: primary, fontWeight: FontWeight.w600),
      side: const BorderSide(color: Color(0x14FFFFFF)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // ── Dividers ──────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: subtleBorder,
      thickness: 1,
      space: 1,
    ),

    // ── Progress indicators ───────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: popupBg,
      circularTrackColor: popupBg,
    ),

    // ── Tooltips ──────────────────────────────────────────────────────────
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: popupBg,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      waitDuration: const Duration(milliseconds: 400),
    ),

    // ── List tiles ────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      iconColor: mutedText,
      textColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
  );
}