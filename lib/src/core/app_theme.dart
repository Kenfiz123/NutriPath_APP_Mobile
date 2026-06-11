import 'package:flutter/material.dart';

class NutriColors {
  const NutriColors._();

  static const primary = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF22C55E);
  static const background = Color(0xFFF9F9F7);
  static const foreground = Color(0xFF1C1C1C);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6B7280);
  static const blue = Color(0xFF3B82F6);
  static const amber = Color(0xFFF59E0B);
  static const teal = Color(0xFF14B8A6);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFFA855F7);
  static const emerald = Color(0xFF10B981);
  static const slate950 = Color(0xFF0F172A);
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
  static const page = 16.0;
}

ThemeData buildNutriTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final seed = isDark ? NutriColors.primaryDark : NutriColors.primary;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    primary: seed,
    surface: isDark ? NutriColors.slate950 : NutriColors.background,
    onSurface: isDark ? Colors.white : NutriColors.foreground,
    error: NutriColors.red,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? NutriColors.slate950
        : NutriColors.background,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: isDark ? NutriColors.slate950 : NutriColors.background,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? NutriColors.slate800 : NutriColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? NutriColors.slate700 : const Color(0x1A1C1C1C),
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? NutriColors.slate800 : const Color(0xFFF3F3F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: seed, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedColor: seed.withValues(alpha: 0.16),
      side: BorderSide(
        color: isDark ? NutriColors.slate700 : const Color(0xFFE5E7EB),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? NutriColors.slate800 : Colors.white,
      indicatorColor: seed.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : null,
        ),
      ),
    ),
  );
}
