import 'package:flutter/material.dart';

// ─── Design tokens — single source of truth ───────────────────────────────────
abstract class AppTheme {
  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color backgroundDeep = Color(0xFF141827);
  static const Color backgroundCard = Color(0xFF1F2638);
  static const Color backgroundAlt = Color(0xFF293148);

  // ── Base greens ─────────────────────────────────────────────────────────────
  static const Color primaryGreenDeep = Color(0xFF102018);
  static const Color primaryGreenMid = Color(0xFF1C3A2A);
  static const Color primaryGreen = Color(0xFF5FAF78);
  static const Color primaryGreenLight = Color(0xFF7BBF8A);
  static const Color primaryGreenMuted = Color(0xFF8FCFA0);

  // ── Accent: Little Wonders BG rose / lavender style ───────────────────────
  static const Color accentOrange = Color(0xFFD77FA1); // soft rose
  static const Color accentPurple = Color(0xFF9B6FD3); // soft lavender
  static const Color accentGold = Color(0xFFE8B84B);
  static const Color accentGlow = Color(0xFFE7A6C4);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEEF5F0);
  static const Color textSecondary = Color(0xFFB0C4B8);
  static const Color textMuted = Color(0xFF6B8A76);

  // ── Glass system ─────────────────────────────────────────────────────────
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassSurfaceVariant = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF7BBF8A);
  static const Color error = Color(0xFFE05252);
  static const Color warning = Color(0xFFE8B84B);

  // ── Badge / category colours ─────────────────────────────────────────────
  static const Color badgeSummit = Color(0xFFD77FA1);
  static const Color badgeNature = Color(0xFF7BBF8A);
  static const Color badgeCulture = Color(0xFFC9A66B);
  static const Color badgeWater = Color(0xFF7DBBC3);
  static const Color badgePurpleColor = Color(0xFF9B6FD3);
  static const Color badgeBlue = Color(0xFF7D9FD3);

  // ── Radius ───────────────────────────────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusFull = 999;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF211832),
      Color(0xFF2E2043),
      Color(0xFF3A244D),
      Color(0xFF24182F),
    ],
    stops: [0.0, 0.35, 0.72, 1.0],
  );

  static const LinearGradient nature = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF254D35),
      Color(0xFF7BBF8A),
    ],
  );

  static const LinearGradient culture = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A3824),
      Color(0xFFC9A66B),
    ],
  );

  static const LinearGradient rosePurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B6FD3),
      Color(0xFFD77FA1),
    ],
  );

  static const LinearGradient badgeOrange = LinearGradient(
    colors: [
      Color(0xFF9B6FD3),
      Color(0xFFD77FA1),
    ],
  );

  static const LinearGradient badgeGreen = LinearGradient(
    colors: [
      Color(0xFF5FAF78),
      Color(0xFF7BBF8A),
    ],
  );

  static const LinearGradient badgePurple = LinearGradient(
    colors: [
      Color(0xFF7B55B8),
      Color(0xFF9B6FD3),
    ],
  );

  static const LinearGradient badgeBlueG = LinearGradient(
    colors: [
      Color(0xFF5F82B8),
      Color(0xFF7D9FD3),
    ],
  );

  static const LinearGradient badgeRed = LinearGradient(
    colors: [
      Color(0xFFB85F72),
      Color(0xFFD77F92),
    ],
  );

  static const LinearGradient badgeTeal = LinearGradient(
    colors: [
      Color(0xFF5AA0A8),
      Color(0xFF7DBBC3),
    ],
  );

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get roseGlowShadow => [
        BoxShadow(
          color: accentOrange.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  // ── MaterialApp themes ───────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDeep,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentOrange,
          brightness: Brightness.dark,
        ).copyWith(
          primary: accentOrange,
          secondary: accentPurple,
          surface: backgroundCard,
        ),
        fontFamily: 'Karla',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            fontSize: 42,
            color: textPrimary,
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            fontSize: 34,
            color: textPrimary,
            letterSpacing: -1.0,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
            fontSize: 28,
            color: textPrimary,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: textSecondary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: textSecondary,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textPrimary,
            letterSpacing: 0.3,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: textMuted,
            letterSpacing: 0.8,
          ),
        ),
        cardTheme: CardThemeData(
          color: backgroundCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundCard,
          contentTextStyle: TextStyle(
            fontFamily: 'Karla',
            color: textPrimary,
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Karla',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF253545),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
      );

  static ThemeData get theme => darkTheme;
  static ThemeData get lightTheme => darkTheme;
}
