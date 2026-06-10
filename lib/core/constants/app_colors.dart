import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const background = Color(0xFF030303); // spec bg-0
  static const surface    = Color(0xFF120605); // card primary
  static const surface2   = Color(0xFF1B0A08); // card elevated
  static const surface3   = Color(0xFF2A1410); // borders / dividers

  // ── Brand palette ─────────────────────────────────────────────────────────
  static const primary     = Color(0xFFD50000); // brand red
  static const primaryDark = Color(0xFF7A0000); // deep red (hero gradient start)
  static const orange      = Color(0xFFFF8A00); // brand orange
  static const orangeLight = Color(0xFFFF6A00); // mid CTA orange
  static const accent      = Color(0xFFFFD21A); // gold

  // ── FAB ───────────────────────────────────────────────────────────────────
  static const fabBg   = Color(0xFFFFD21A); // gold
  static const fabIcon = Color(0xFF0A0000); // near-black

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFF7F5F2); // warm white per spec text-1
  static const textSecondary = Color(0xFFB7B0A8); // warm gray per spec text-2
  static const text3         = Color(0xFF746E68); // spec text-3

  // ── Borders ───────────────────────────────────────────────────────────────
  static const borderSoft = Color(0x24FFB428); // rgba(255,180,40,.14) — card border
  static const borderGold = Color(0x73FFAE00); // rgba(255,174,0,.45) — premium
  static const borderRed  = Color(0x73FF2312); // rgba(255,35,18,.45)

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const success = Color(0xFF63D728); // spec green
  static const error   = Color(0xFFFF3B30); // distinct from primary brand red
  static const info    = Color(0xFF4FC3F7);
  static const warning = Color(0xFFFF8A00);

  // ── Medal colours ──────────────────────────────────────────────────────────
  static const goldMedal   = Color(0xFFFFD21A);
  static const silverMedal = Color(0xFFB0BEC5);
  static const bronzeMedal = Color(0xFFCD7F32);

  // ── Avatar palette — deterministic by athlete ID ──────────────────────────
  static const List<Color> avatarColors = [
    Color(0xFFD32F2F), // red
    Color(0xFF7B1FA2), // purple
    Color(0xFF1565C0), // blue
    Color(0xFF2E7D32), // green
    Color(0xFFEF6C00), // orange
    Color(0xFF00838F), // cyan
  ];

  static Color avatarColor(String seed) {
    final code = seed.codeUnits.fold(0, (a, b) => a + b);
    return avatarColors[code % avatarColors.length];
  }

  // ── Gradients ─────────────────────────────────────────────────────────────

  /// Main CTA: spec gradient-primary — #e40000 → #ff260f → #ff8a00 → #ffd21a
  static const ctaGradient = LinearGradient(
    stops: [0.0, 0.42, 0.74, 1.0],
    colors: [Color(0xFFE40000), Color(0xFFFF260F), Color(0xFFFF8A00), Color(0xFFFFD21A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Hero card: linear-gradient(135deg, #7A0000 0%, #D50000 60%, #FF8A00 100%)
  static const heroCardGradient = LinearGradient(
    stops: [0.0, 0.6, 1.0],
    colors: [Color(0xFF7A0000), Color(0xFFD50000), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,    // 135deg = top-left → bottom-right
    end: Alignment.bottomRight,
  );

  // Alias for backwards compat
  static const redGoldGradient = ctaGradient;
  static const redGradient     = ctaGradient;

  // Legacy aliases
  static const primaryLight = Color(0xFFFF6A00);
  static const accentDark   = Color(0xFFCC9A00);
  static const divider      = surface3;
  static const red          = Color(0xFFD50000);
}
