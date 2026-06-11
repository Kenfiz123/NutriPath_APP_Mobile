import 'package:flutter/material.dart';

class NutriColors {
  const NutriColors._();

  static const primary = Color(0xFF10B981); // Emerald 500
  static const primaryDark = Color(0xFF059669); // Emerald 600
  static const background = Color(0xFFF9FAFB); // Gray 50
  static const foreground = Color(0xFF111827); // Gray 900
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6B7280); // Gray 500
  static const blue = Color(0xFF3B82F6);
  static const amber = Color(0xFFF59E0B);
  static const orange = Color(0xFFF97316);
  static const teal = Color(0xFF14B8A6);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFFA855F7);
  static const emerald = Color(0xFF10B981);
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate300 = Color(0xFFCBD5E1);
}

class NutriSpacing {
  const NutriSpacing._();

  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 16.0;
  static const radius = 16.0;
}

ThemeData buildNutriTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final seed = isDark ? NutriColors.primary : NutriColors.primary;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    primary: seed,
    surface: isDark ? NutriColors.slate900 : NutriColors.background,
    onSurface: isDark ? Colors.white : NutriColors.foreground,
    error: NutriColors.red,
    outlineVariant: isDark ? NutriColors.slate700 : const Color(0xFFE5E7EB),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? NutriColors.slate950
        : NutriColors.background,
    fontFamily: 'Inter',
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: isDark ? NutriColors.slate950 : NutriColors.background,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: isDark ? NutriColors.slate900 : NutriColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NutriSpacing.radius),
        side: BorderSide(
          color: isDark ? NutriColors.slate800 : const Color(0xFFF3F4F6),
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? NutriColors.slate800 : const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? NutriColors.slate700 : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: seed, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: seed, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedColor: seed.withValues(alpha: 0.2),
      side: BorderSide(
        color: isDark ? NutriColors.slate700 : const Color(0xFFE5E7EB),
      ),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? NutriColors.slate900 : Colors.white,
      indicatorColor: seed.withValues(alpha: 0.1),
      elevation: 8,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
        ),
      ),
    ),
  );
}
