import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light glassmorphism / pastel SaaS visual language for PMS Admin.
///
/// Color tokens match the reference PMS Firebase design system.
/// Existing aliases (`brand`, `canvas`, `surface`, `ink`, `muted`, `outline`)
/// are preserved so older screens keep compiling.
abstract final class PmsTheme {
  // Primary palette
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFFEC4899);
  static const Color teal = Color(0xFF0D9488);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color bgSoft = Color(0xFFF1F5F9);
  static const Color backgroundGradientStart = Color(0xFFEFF6FF);
  static const Color backgroundGradientEnd = Color(0xFFFAF5FF);

  // Glass surfaces
  static const Color glassSurface = Color(0xE6FFFFFF);
  static const Color glassSurfaceLight = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x33CBD5E1);
  static const Color glassBorderActive = Color(0x66818CF8);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color verified = Color(0xFF2563EB);

  // Backward-compatible aliases used by existing screens
  static const Color brand = primary;
  static const Color canvas = background;
  static const Color surface = glassSurface;
  static const Color ink = textPrimary;
  static const Color muted = textMuted;
  static const Color outline = glassBorder;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgSoftGradient = LinearGradient(
    colors: [Color(0xFFF0F4FF), Color(0xFFF5F3FF), Color(0xFFFAF5FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient pageGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static BoxDecoration glass({
    double radius = 20,
    bool active = false,
  }) {
    return BoxDecoration(
      color: glassSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: active ? glassBorderActive : glassBorder,
      ),
      boxShadow: active ? glowShadow : glassShadow,
    );
  }

  static TextTheme get _textTheme {
    try {
      return GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
          bodySmall: TextStyle(fontSize: 12, color: textMuted),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      );
    } catch (_) {
      return const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textMuted),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      );
    }
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: primary,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          tertiary: accent,
          surface: glassSurface,
          error: error,
          onPrimary: textWhite,
          onSecondary: textWhite,
          onSurface: textPrimary,
          onError: textWhite,
        ),
        textTheme: _textTheme,
        iconTheme: const IconThemeData(color: textSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: glassSurface,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: textPrimary),
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: glassSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: glassBorder),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.04),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: glassSurfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: const TextStyle(color: textMuted, fontSize: 14),
          labelStyle: const TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: error),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: glassBorderActive),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: primaryLight,
          selectedColor: primary.withValues(alpha: 0.16),
          labelStyle: const TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          side: const BorderSide(color: glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: glassSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: glassBorder),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: glassSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: textPrimary,
          contentTextStyle: const TextStyle(
            color: textWhite,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: const DividerThemeData(color: glassBorder, thickness: 1),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: textWhite,
          elevation: 2,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textMuted,
          indicatorColor: primary,
        ),
      );
}
