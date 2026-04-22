import 'package:flutter/material.dart';

// ─── Design tokens — single source of truth ───────────────────────────────────
abstract class AppTheme {
  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color backgroundDeep  = Color(0xFF0D1B2A);
  static const Color backgroundCard  = Color(0xFF162032);
  static const Color backgroundAlt   = Color(0xFF1C2A3A);

  // ── Aurora greens ─────────────────────────────────────────────────────────
  static const Color primaryGreenDeep  = Color(0xFF061A0E);
  static const Color primaryGreenMid   = Color(0xFF0A2E18);
  static const Color primaryGreen      = Color(0xFF1A7A4A);
  static const Color primaryGreenLight = Color(0xFF22A060);
  static const Color primaryGreenMuted = Color(0xFF2DBD72);

  // ── Accent ───────────────────────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFFF8C00);
  static const Color accentGold   = Color(0xFFE8B84B);
  static const Color accentGlow   = Color(0xFFFFAA33);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEEF5F0);
  static const Color textSecondary = Color(0xFFB0C4B8);
  static const Color textMuted     = Color(0xFF6B8A76);

  // ── Glass system ─────────────────────────────────────────────────────────
  static const Color glassSurface        = Color(0x1AFFFFFF);
  static const Color glassSurfaceVariant = Color(0x26FFFFFF);
  static const Color glassBorder         = Color(0x22FFFFFF);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22A060);
  static const Color error   = Color(0xFFE05252);
  static const Color warning = Color(0xFFE8B84B);

  // ── Badge / category colours ─────────────────────────────────────────────
  static const Color badgeSummit  = Color(0xFFFF8C00);
  static const Color badgeNature  = Color(0xFF22A060);
  static const Color badgeCulture = Color(0xFF8B5A1A);
  static const Color badgeWater   = Color(0xFF4DB6C4);
  static const Color badgePurpleColor = Color(0xFF9B59B6);
  static const Color badgeBlue    = Color(0xFF3498DB);

  // ── Radius ───────────────────────────────────────────────────────────────
  static const double radiusSm   = 12;
  static const double radiusMd   = 18;
  static const double radiusLg   = 24;
  static const double radiusXl   = 32;
  static const double radiusFull = 999;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF061A0E), Color(0xFF0A2E18), Color(0xFF0D3D2E), Color(0xFF1A6B3C)],
    stops: [0.0, 0.3, 0.65, 1.0],
  );
  static const LinearGradient nature = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A2E18), Color(0xFF1A7A4A)],
  );
  static const LinearGradient culture = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF2E1A0A), Color(0xFF8B5A1A)],
  );
  static const LinearGradient badgeOrange = LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFFB347)]);
  static const LinearGradient badgeGreen  = LinearGradient(colors: [Color(0xFF1A8C52), Color(0xFF2ECC71)]);
  static const LinearGradient badgePurple = LinearGradient(colors: [Color(0xFF6B3FA0), Color(0xFF9B59B6)]);
  static const LinearGradient badgeBlueG  = LinearGradient(colors: [Color(0xFF1A52A0), Color(0xFF3498DB)]);
  static const LinearGradient badgeRed    = LinearGradient(colors: [Color(0xFFA01A1A), Color(0xFFE74C3C)]);
  static const LinearGradient badgeTeal   = LinearGradient(colors: [Color(0xFF1A7A7A), Color(0xFF1ABC9C)]);

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4,  offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 0),
  ];

  // ── MaterialApp themes ───────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDeep,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen, brightness: Brightness.dark)
        .copyWith(primary: primaryGreen, secondary: accentOrange, surface: backgroundCard),
    fontFamily: 'Karla',
    textTheme: const TextTheme(
      displayLarge:   TextStyle(fontFamily: 'Lora',  fontWeight: FontWeight.w700, fontSize: 42, color: textPrimary, letterSpacing: -1.5),
      displayMedium:  TextStyle(fontFamily: 'Lora',  fontWeight: FontWeight.w700, fontSize: 34, color: textPrimary, letterSpacing: -1.0),
      displaySmall:   TextStyle(fontFamily: 'Lora',  fontWeight: FontWeight.w600, fontSize: 28, color: textPrimary),
      headlineLarge:  TextStyle(fontFamily: 'Lora',  fontWeight: FontWeight.w700, fontSize: 24, color: textPrimary),
      headlineMedium: TextStyle(fontFamily: 'Lora',  fontWeight: FontWeight.w600, fontSize: 20, color: textPrimary),
      bodyLarge:      TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w400, fontSize: 16, color: textSecondary, height: 1.6),
      bodyMedium:     TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w400, fontSize: 14, color: textSecondary, height: 1.5),
      labelLarge:     TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary, letterSpacing: 0.3),
      labelMedium:    TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w600, fontSize: 11, color: textMuted, letterSpacing: 0.8),
    ),
    cardTheme: CardThemeData(
      color: backgroundCard, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundCard,
      contentTextStyle: TextStyle(fontFamily: 'Karla', color: textPrimary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentOrange, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF253545), thickness: 1),
    iconTheme: const IconThemeData(color: textSecondary),
  );

  static ThemeData get theme => darkTheme;       // convenience alias
  static ThemeData get lightTheme => darkTheme; // App is dark-only
}