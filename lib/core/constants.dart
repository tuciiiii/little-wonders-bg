import 'package:flutter/material.dart';

// ── Dark Premium Palette ──────────────────────────────────────────────────────
abstract class AppColors {
  // Dark backgrounds
  static const darkBg         = Color(0xFF0D1B2A);  // deep navy
  static const darkCard       = Color(0xFF162032);  // card surface
  static const darkCardAlt    = Color(0xFF1C2A3A);  // alternate card
  static const darkBorder     = Color(0xFF253545);  // subtle border

  // Light backgrounds (login only)
  static const bg             = Color(0xFF0D1B2A);
  static const bgCard         = Color(0xFF162032);
  static const bgDim          = Color(0xFF1C2A3A);
  static const bgMuted        = Color(0xFF253545);

  // Aurora greens
  static const primary        = Color(0xFF1A7A4A);
  static const primaryLight   = Color(0xFF22A060);
  static const primaryMuted   = Color(0xFF2DBD72);
  static const auroraDeep     = Color(0xFF061A0E);
  static const auroraMid      = Color(0xFF0A2E18);
  static const auroraGreen    = Color(0xFF1A6B3C);
  static const auroraTeal     = Color(0xFF0D3D2E);
  static const auroraLight    = Color(0xFF1E8C52);
  static const auroraMist     = Color(0xFF2EAA68);

  // Accent — warm orange/gold like the reference
  static const accent         = Color(0xFFFF8C00);  // orange accent
  static const accentGold     = Color(0xFFE8B84B);
  static const accentGlow     = Color(0xFFFFAA33);
  static const accentLight    = Color(0xFFFFAA33); // alias

  // Text
  static const textDark       = Color(0xFFEEF5F0);  // near white on dark
  static const textMid        = Color(0xFFB0C4B8);
  static const textLight      = Color(0xFF6B8A76);
  static const textOnDark     = Color(0xFFEEF5F0);

  // Semantic
  static const success        = Color(0xFF22A060);
  static const error          = Color(0xFFE05252);
  static const warning        = Color(0xFFE8B84B);

  // Glass
  static const glass          = Color(0x1AFFFFFF);
  static const glassBorder    = Color(0x22FFFFFF);

  // Category
  static const nature         = Color(0xFF1A7A4A);
  static const culture        = Color(0xFF7A4A1A);

  // Legacy aliases used in widgets
  static const gradTop        = Color(0xFF061A0E);
  static const gradMid        = Color(0xFF0A2E18);
  static const gradBot        = Color(0xFF1A6B3C);
}

abstract class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

abstract class AppRadius {
  static const sm   = Radius.circular(12);
  static const md   = Radius.circular(18);
  static const lg   = Radius.circular(24);
  static const xl   = Radius.circular(32);
  static const xxl  = Radius.circular(40);
  static const full = Radius.circular(999);
}

abstract class AppGradients {
  static const aurora = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF061A0E), Color(0xFF0A2E18), Color(0xFF0D3D2E), Color(0xFF1A6B3C)],
    stops: [0.0, 0.3, 0.65, 1.0],
  );
  static const header = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFF061A0E), Color(0xFF0A2E18), Color(0xFF1A6B3C)],
  );
  static const cardOverlay = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xDD0D1B2A)],
    stops: [0.3, 1.0],
  );
  static const nature = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A2E18), Color(0xFF1A7A4A)],
  );
  static const culture = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF2E1A0A), Color(0xFF8B5A1A)],
  );
  // Badge gradients
  static const badgeOrange = LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFFB347)]);
  static const badgeGreen  = LinearGradient(colors: [Color(0xFF1A8C52), Color(0xFF2ECC71)]);
  static const badgePurple = LinearGradient(colors: [Color(0xFF6B3FA0), Color(0xFF9B59B6)]);
  static const badgeBlue   = LinearGradient(colors: [Color(0xFF1A52A0), Color(0xFF3498DB)]);
  static const badgeRed    = LinearGradient(colors: [Color(0xFFA01A1A), Color(0xFFE74C3C)]);
  static const badgeTeal   = LinearGradient(colors: [Color(0xFF1A7A7A), Color(0xFF1ABC9C)]);
}

abstract class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> glow = [
    BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 0),
  ];
  static List<BoxShadow> accentGlow = [
    BoxShadow(color: AppColors.accent.withValues(alpha: 0.40), blurRadius: 16, spreadRadius: 0),
  ];
}

abstract class GameConstants {
  static const checkInRadiusMeters = 150.0;
  static const levelThresholds     = [0, 100, 250, 500, 800, 1200];
  static const levelNames          = ['Beginner', 'Rookie', 'Explorer', 'Adventurer', 'Summit Master', 'Legend'];

  static String levelName(int points) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (points >= levelThresholds[i]) return levelNames[i];
    }
    return levelNames[0];
  }

  static double levelProgress(int points) {
    for (int i = 0; i < levelThresholds.length - 1; i++) {
      if (points < levelThresholds[i + 1]) {
        return ((points - levelThresholds[i]) / (levelThresholds[i + 1] - levelThresholds[i])).clamp(0.0, 1.0);
      }
    }
    return 1.0;
  }

  static String nextLevelName(int points) {
    for (int i = 0; i < levelThresholds.length - 1; i++) {
      if (points < levelThresholds[i + 1]) return levelNames[i + 1];
    }
    return 'Legend';
  }

  static int pointsToNextLevel(int points) {
    for (int i = 0; i < levelThresholds.length - 1; i++) {
      if (points < levelThresholds[i + 1]) return levelThresholds[i + 1] - points;
    }
    return 0;
  }
}