import 'package:flutter/material.dart';

/// Premium Design System Colors
/// Fusion of:
/// - Chinese: Elegant reds, subtle earth tones, ink blacks
/// - American: Bold contrasts, vibrant accents, clean whites
/// - European: Sophisticated neutrals, refined gold, deep navys
class DesignColors {
  DesignColors._();

  // ══════════════════════════════════════════════════════════════
  // PRIMARY BRAND PALETTE
  // ══════════════════════════════════════════════════════════════

  /// Primary - Deep Navy (European elegance)
  static const Color primary = Color(0xFF1A1F36);
  static const Color primaryLight = Color(0xFF2D3452);
  static const Color primaryDark = Color(0xFF0D1119);

  /// Accent - Royal Gold (Chinese prosperity)
  static const Color accent = Color(0xFFD4AF37);
  static const Color accentLight = Color(0xFFE8C966);
  static const Color accentDark = Color(0xFFB8941F);

  /// Secondary - Electric Blue (American modernity)
  static const Color secondary = Color(0xFF4169E1);
  static const Color secondaryLight = Color(0xFF6B8DF5);
  static const Color secondaryDark = Color(0xFF2E4AB8);

  // ══════════════════════════════════════════════════════════════
  // FEATURE ACCENT COLORS
  // ══════════════════════════════════════════════════════════════

  /// Vision - Mystical Purple
  static const Color vision = Color(0xFF7C3AED);
  static const Color visionLight = Color(0xFF9F67FF);
  static const Color visionSurface = Color(0xFFF3EEFF);

  /// NLP - Jade Green (Chinese jade)
  static const Color nlp = Color(0xFF00A86B);
  static const Color nlpLight = Color(0xFF2DD4A0);
  static const Color nlpSurface = Color(0xFFECFDF5);

  /// Generative - Crimson Red (Chinese luck)
  static const Color generative = Color(0xFFDC2626);
  static const Color generativeLight = Color(0xFFF87171);
  static const Color generativeSurface = Color(0xFFFEF2F2);

  // ══════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ══════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // ══════════════════════════════════════════════════════════════
  // LIGHT THEME NEUTRALS
  // ══════════════════════════════════════════════════════════════

  /// Background - Warm white (European)
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Borders
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderSubtleLight = Color(0xFFF3F4F6);
  static const Color dividerLight = Color(0xFFE5E7EB);

  /// Text
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textDisabledLight = Color(0xFFD1D5DB);

  // ══════════════════════════════════════════════════════════════
  // DARK THEME NEUTRALS
  // ══════════════════════════════════════════════════════════════

  /// Background - Deep ink (Chinese ink)
  static const Color backgroundDark = Color(0xFF0A0A0B);
  static const Color surfaceDark = Color(0xFF141417);
  static const Color cardDark = Color(0xFF1C1C21);

  /// Borders
  static const Color borderDark = Color(0xFF2D2D35);
  static const Color borderSubtleDark = Color(0xFF232329);
  static const Color dividerDark = Color(0xFF2D2D35);

  /// Text
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color textTertiaryDark = Color(0xFF71717A);
  static const Color textDisabledDark = Color(0xFF52525B);

  // ══════════════════════════════════════════════════════════════
  // GRADIENTS
  // ══════════════════════════════════════════════════════════════

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF1A1F36), Color(0xFF2D3452)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient visionGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nlpGradient = LinearGradient(
    colors: [Color(0xFF00A86B), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient generativeGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x33FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ══════════════════════════════════════════════════════════════
  // SHADOWS
  // ══════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowXl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> shadowColored(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
