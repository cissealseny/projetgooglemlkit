import 'package:flutter/material.dart';

/// Premium Typography System
/// - Headlines: Inter (clean, modern - American)
/// - Body: Inter (highly legible - European)
/// - Display: Playfair Display for premium sections (European elegance)
class DesignTypography {
  DesignTypography._();

  // ══════════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ══════════════════════════════════════════════════════════════

  static String get primaryFont => 'sans-serif';
  static String get displayFont => 'serif';
  static String get monoFont => 'monospace';

  // ══════════════════════════════════════════════════════════════
  // DISPLAY STYLES (Premium headers)
  // ══════════════════════════════════════════════════════════════

  static TextStyle displayLarge(Color color) => TextStyle(
        fontFamily: displayFont,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.5,
        color: color,
      );

  static TextStyle displayMedium(Color color) => TextStyle(
        fontFamily: displayFont,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -1,
        color: color,
      );

  static TextStyle displaySmall(Color color) => TextStyle(
        fontFamily: displayFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.5,
        color: color,
      );

  // ══════════════════════════════════════════════════════════════
  // HEADLINE STYLES (Section headers)
  // ══════════════════════════════════════════════════════════════

  static TextStyle headlineLarge(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headlineMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.25,
        color: color,
      );

  static TextStyle headlineSmall(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // ══════════════════════════════════════════════════════════════
  // TITLE STYLES (Cards, dialogs)
  // ══════════════════════════════════════════════════════════════

  static TextStyle titleLarge(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: color,
      );

  static TextStyle titleMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: color,
      );

  static TextStyle titleSmall(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: color,
      );

  // ══════════════════════════════════════════════════════════════
  // BODY STYLES (Content text)
  // ══════════════════════════════════════════════════════════════

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: color,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  // ══════════════════════════════════════════════════════════════
  // LABEL STYLES (Buttons, chips, form labels)
  // ══════════════════════════════════════════════════════════════

  static TextStyle labelLarge(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle labelSmall(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.4,
        color: color,
      );

  // ══════════════════════════════════════════════════════════════
  // SPECIAL STYLES
  // ══════════════════════════════════════════════════════════════

  static TextStyle code(Color color) => TextStyle(
        fontFamily: monoFont,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle button(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle overline(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 1.5,
        color: color,
      );
}

/// Premium Spacing System (8pt grid)
class DesignSpacing {
  DesignSpacing._();

  // Base unit
  static const double unit = 8.0;

  // Spacing scale
  static const double xxs = 2.0; // 0.25x
  static const double xs = 4.0; // 0.5x
  static const double sm = 8.0; // 1x
  static const double md = 16.0; // 2x
  static const double lg = 24.0; // 3x
  static const double xl = 32.0; // 4x
  static const double xxl = 48.0; // 6x
  static const double xxxl = 64.0; // 8x

  // Page padding
  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets pageVertical = EdgeInsets.symmetric(vertical: 16);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  // Safe area
  static const double bottomNavHeight = 72.0;
  static const double appBarHeight = 56.0;
}

/// Premium Border Radius
class DesignRadius {
  DesignRadius._();

  static const double none = 0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;

  static BorderRadius get radiusXs => BorderRadius.circular(xs);
  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusXxl => BorderRadius.circular(xxl);
  static BorderRadius get radiusFull => BorderRadius.circular(full);
}

/// Animation durations
class DesignDurations {
  DesignDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 350);
}

/// Animation curves
class DesignCurves {
  DesignCurves._();

  static const Curve ease = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve smooth = Curves.fastOutSlowIn;
}
