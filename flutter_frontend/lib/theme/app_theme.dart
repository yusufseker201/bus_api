import 'package:flutter/material.dart';

class AppTheme {
  static const Color teal = Color(0xFF1D7E73);
  static const Color deepTeal = Color(0xFF0F5B57);
  static const Color mint = Color(0xFFDDF6EE);
  static const Color paleMint = Color(0xFFF2FBF8);
  static const Color shell = Color(0xFFFCFDF9);
  static const Color text = Color(0xFF183B39);
  static const Color muted = Color(0xFF67817F);
  static const double radius = 16;

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
    ).copyWith(
      primary: teal,
      onPrimary: Colors.white,
      secondary: const Color(0xFF8FD9C8),
      onSecondary: text,
      error: const Color(0xFFB83D3D),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: text,
      primaryContainer: const Color(0xFFCBEFE5),
      onPrimaryContainer: deepTeal,
      secondaryContainer: const Color(0xFFE8FBF3),
      onSecondaryContainer: text,
      tertiary: const Color(0xFF52B7A5),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFD9F7F0),
      onTertiaryContainer: deepTeal,
      surfaceContainerHighest: const Color(0xFFEAF5F1),
      onSurfaceVariant: muted,
      outline: const Color(0xFFB9D8D0),
      outlineVariant: const Color(0xFFD9EBE5),
      shadow: const Color(0x1F0D4A45),
      scrim: const Color(0x660C3836),
      inverseSurface: deepTeal,
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFF9AE3D4),
      surfaceTint: teal,
    );

    final textTheme = ThemeData.light(useMaterial3: true).textTheme.apply(
          bodyColor: text,
          displayColor: text,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: shell,
      textTheme: textTheme.copyWith(
        headlineLarge:
            textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        headlineMedium:
            textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        headlineSmall:
            textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium:
            textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.35),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.35),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: Color(0xFFE0F1EB)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paleMint,
        selectedColor: mint,
        disabledColor: const Color(0xFFF0F3F2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: const BorderSide(color: Color(0xFFDDEDE8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepTeal,
          side: const BorderSide(color: Color(0xFFC5E7DF)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: deepTeal,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFD8ECE6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFD8ECE6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: teal, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: mint,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: const Color(0xFFE1EEEA),
    );
  }

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x140B4741),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ];
}
