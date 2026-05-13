import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.green,
    required this.greenInk,
    required this.greenDim,
    required this.greenBorder,
    required this.greenSurface,
    required this.amber,
    required this.amberInk,
    required this.amberDim,
    required this.red,
    required this.redInk,
    required this.redDim,
    required this.blue,
    required this.blueDim,
    required this.purple,
    required this.purpleDim,
    required this.purpleBorder,
    required this.teal,
    required this.tealDim,
  });

  final Color background;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color green;
  final Color greenInk;
  final Color greenDim;
  final Color greenBorder;
  final Color greenSurface;
  final Color amber;
  final Color amberInk;
  final Color amberDim;
  final Color red;
  final Color redInk;
  final Color redDim;
  final Color blue;
  final Color blueDim;
  final Color purple;
  final Color purpleDim;
  final Color purpleBorder;
  final Color teal;
  final Color tealDim;

  static AppColors of(BuildContext context) {
    final extension = Theme.of(context).extension<AppColors>();
    if (extension != null) return extension;
    return Theme.of(context).brightness == Brightness.light ? light : dark;
  }

  static const AppColors dark = AppColors(
    background: Color(0xFF0E0F11),
    surface: Color(0xFF17181C),
    surface2: Color(0xFF1F2026),
    surface3: Color(0xFF26272E),
    border: Color(0xFF2E2F38),
    borderSubtle: Color(0x332E2F38),
    textPrimary: Color(0xFFF0F0F2),
    textSecondary: Color(0xFF8B8C99),
    textTertiary: Color(0xFF555663),
    green: Color(0xFF4ADE80),
    greenInk: Color(0xFF4ADE80),
    greenDim: Color(0xFF1A3828),
    greenBorder: Color(0x664ADE80),
    greenSurface: Color(0x1A4ADE80),
    amber: Color(0xFFFBBF24),
    amberInk: Color(0xFFFBBF24),
    amberDim: Color(0xFF2D2310),
    red: Color(0xFFF87171),
    redInk: Color(0xFFF87171),
    redDim: Color(0xFF2D1515),
    blue: Color(0xFF60A5FA),
    blueDim: Color(0xFF0F1F35),
    purple: Color(0xFFA78BFA),
    purpleDim: Color(0xFF1E1530),
    purpleBorder: Color(0x66A78BFA),
    teal: Color(0xFF2DD4BF),
    tealDim: Color(0xFF0D2825),
  );

  static const AppColors light = AppColors(
    background: Color(0xFFF6F7F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF1F2F4),
    surface3: Color(0xFFE6E8EC),
    border: Color(0xFFE2E4E9),
    borderSubtle: Color(0x0F0E0F11),
    textPrimary: Color(0xFF0E0F11),
    textSecondary: Color(0xFF5A5F6B),
    textTertiary: Color(0xFF9AA0A6),
    green: Color(0xFF22C55E),
    greenInk: Color(0xFF15803D),
    greenDim: Color(0xFFDCFCE7),
    greenBorder: Color(0xFFBBF7D0),
    greenSurface: Color(0xFFDCFCE7),
    amber: Color(0xFFD97706),
    amberInk: Color(0xFF92400E),
    amberDim: Color(0xFFFEF3C7),
    red: Color(0xFFDC2626),
    redInk: Color(0xFF991B1B),
    redDim: Color(0xFFFEE2E2),
    blue: Color(0xFF2563EB),
    blueDim: Color(0xFFDBEAFE),
    purple: Color(0xFF7C3AED),
    purpleDim: Color(0xFFEDE9FE),
    purpleBorder: Color(0xFFDDD6FE),
    teal: Color(0xFF0D9488),
    tealDim: Color(0xFFCCFBF1),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? green,
    Color? greenInk,
    Color? greenDim,
    Color? greenBorder,
    Color? greenSurface,
    Color? amber,
    Color? amberInk,
    Color? amberDim,
    Color? red,
    Color? redInk,
    Color? redDim,
    Color? blue,
    Color? blueDim,
    Color? purple,
    Color? purpleDim,
    Color? purpleBorder,
    Color? teal,
    Color? tealDim,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      green: green ?? this.green,
      greenInk: greenInk ?? this.greenInk,
      greenDim: greenDim ?? this.greenDim,
      greenBorder: greenBorder ?? this.greenBorder,
      greenSurface: greenSurface ?? this.greenSurface,
      amber: amber ?? this.amber,
      amberInk: amberInk ?? this.amberInk,
      amberDim: amberDim ?? this.amberDim,
      red: red ?? this.red,
      redInk: redInk ?? this.redInk,
      redDim: redDim ?? this.redDim,
      blue: blue ?? this.blue,
      blueDim: blueDim ?? this.blueDim,
      purple: purple ?? this.purple,
      purpleDim: purpleDim ?? this.purpleDim,
      purpleBorder: purpleBorder ?? this.purpleBorder,
      teal: teal ?? this.teal,
      tealDim: tealDim ?? this.tealDim,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenInk: Color.lerp(greenInk, other.greenInk, t)!,
      greenDim: Color.lerp(greenDim, other.greenDim, t)!,
      greenBorder: Color.lerp(greenBorder, other.greenBorder, t)!,
      greenSurface: Color.lerp(greenSurface, other.greenSurface, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberInk: Color.lerp(amberInk, other.amberInk, t)!,
      amberDim: Color.lerp(amberDim, other.amberDim, t)!,
      red: Color.lerp(red, other.red, t)!,
      redInk: Color.lerp(redInk, other.redInk, t)!,
      redDim: Color.lerp(redDim, other.redDim, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueDim: Color.lerp(blueDim, other.blueDim, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      purpleDim: Color.lerp(purpleDim, other.purpleDim, t)!,
      purpleBorder: Color.lerp(purpleBorder, other.purpleBorder, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealDim: Color.lerp(tealDim, other.tealDim, t)!,
    );
  }
}
