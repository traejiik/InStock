import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();
    final onPrimary = brightness == Brightness.light
        ? const Color(0xFF062014)
        : c.background;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness: brightness,
        surface: c.surface,
        primary: c.green,
        onPrimary: onPrimary,
        secondary: c.purple,
        onSecondary: c.textPrimary,
        error: c.red,
        onError: c.surface,
        onSurface: c.textPrimary,
        outline: c.border,
        primaryContainer: c.greenDim,
        onPrimaryContainer: c.greenInk,
        secondaryContainer: c.purpleDim,
        onSecondaryContainer: c.textPrimary,
        errorContainer: c.redDim,
        onErrorContainer: c.redInk,
        surfaceContainerHighest: c.surface3,
        onSurfaceVariant: c.textSecondary,
        outlineVariant: c.borderSubtle,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
      dividerColor: c.border,
      cardColor: c.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.green),
        ),
        labelStyle: TextStyle(color: c.textSecondary),
        hintStyle: TextStyle(color: c.textTertiary),
        floatingLabelStyle: TextStyle(
          color: brightness == Brightness.light ? c.greenInk : c.green,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.green,
        foregroundColor: onPrimary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.green,
        unselectedItemColor: c.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface3,
        labelStyle: TextStyle(color: c.textSecondary, fontSize: 12),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
          height: 1.3,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface2,
        contentTextStyle: TextStyle(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
