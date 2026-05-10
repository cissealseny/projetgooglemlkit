import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_colors.dart';
import 'design_tokens.dart';

/// Premium Application Theme
/// Mobile-first design with international fusion aesthetics
class PremiumTheme {
  PremiumTheme._();

  // ══════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: DesignColors.primary,
      onPrimary: Colors.white,
      primaryContainer: DesignColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: DesignColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: DesignColors.secondaryLight,
      onSecondaryContainer: Colors.white,
      tertiary: DesignColors.accent,
      onTertiary: DesignColors.primary,
      surface: DesignColors.surfaceLight,
      onSurface: DesignColors.textPrimaryLight,
      surfaceContainerHighest: DesignColors.cardLight,
      error: DesignColors.error,
      onError: Colors.white,
      outline: DesignColors.borderLight,
      outlineVariant: DesignColors.borderSubtleLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DesignColors.backgroundLight,

      // Visual Density for more compact mobile UI
      visualDensity: VisualDensity.compact,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: DesignColors.surfaceLight,
        foregroundColor: DesignColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle:
            DesignTypography.titleLarge(DesignColors.textPrimaryLight),
        iconTheme: const IconThemeData(
          color: DesignColors.textPrimaryLight,
          size: 22,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: DesignColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusLg,
          side: const BorderSide(color: DesignColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Cards
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DesignColors.textDisabledLight,
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: DesignRadius.radiusMd,
          ),
          elevation: 0,
          textStyle: DesignTypography.button(Colors.white),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: DesignRadius.radiusMd,
          ),
          side: const BorderSide(color: DesignColors.primary, width: 1.5),
          textStyle: DesignTypography.button(DesignColors.primary),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: DesignTypography.button(DesignColors.primary),
        ),
      ),

      // Filled Buttons (accent)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DesignColors.accent,
          foregroundColor: DesignColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: DesignRadius.radiusMd,
          ),
          textStyle: DesignTypography.button(DesignColors.primary),
        ),
      ),

      // Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: DesignColors.textSecondaryLight,
          padding: const EdgeInsets.all(10),
          minimumSize: const Size(40, 40),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DesignColors.accent,
        foregroundColor: DesignColors.primary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusLg,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignColors.backgroundLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.error, width: 2),
        ),
        hintStyle: DesignTypography.bodyMedium(DesignColors.textTertiaryLight),
        labelStyle:
            DesignTypography.bodyMedium(DesignColors.textSecondaryLight),
        errorStyle: DesignTypography.bodySmall(DesignColors.error),
        prefixIconColor: DesignColors.textSecondaryLight,
        suffixIconColor: DesignColors.textSecondaryLight,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: DesignColors.surfaceLight,
        selectedItemColor: DesignColors.primary,
        unselectedItemColor: DesignColors.textTertiaryLight,
        selectedLabelStyle: DesignTypography.labelSmall(DesignColors.primary),
        unselectedLabelStyle:
            DesignTypography.labelSmall(DesignColors.textTertiaryLight),
        elevation: 8,
        showUnselectedLabels: true,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        height: DesignSpacing.bottomNavHeight,
        backgroundColor: DesignColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: DesignColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: DesignColors.primary, size: 24);
          }
          return const IconThemeData(
              color: DesignColors.textTertiaryLight, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTypography.labelSmall(DesignColors.primary);
          }
          return DesignTypography.labelSmall(DesignColors.textTertiaryLight);
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: DesignColors.backgroundLight,
        selectedColor: DesignColors.primary.withValues(alpha: 0.15),
        disabledColor: DesignColors.borderSubtleLight,
        labelStyle: DesignTypography.labelMedium(DesignColors.textPrimaryLight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusFull,
          side: const BorderSide(color: DesignColors.borderLight),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: DesignColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusXl,
        ),
        titleTextStyle:
            DesignTypography.headlineSmall(DesignColors.textPrimaryLight),
        contentTextStyle:
            DesignTypography.bodyMedium(DesignColors.textSecondaryLight),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DesignColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: DesignColors.surfaceLight,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignRadius.xl),
          ),
        ),
        dragHandleColor: DesignColors.borderLight,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DesignColors.primary,
        contentTextStyle: DesignTypography.bodyMedium(Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusMd,
        ),
        elevation: 4,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: DesignColors.dividerLight,
        thickness: 1,
        space: 1,
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        contentPadding: DesignSpacing.listItemPadding,
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusMd,
        ),
        titleTextStyle:
            DesignTypography.titleSmall(DesignColors.textPrimaryLight),
        subtitleTextStyle:
            DesignTypography.bodySmall(DesignColors.textSecondaryLight),
        leadingAndTrailingTextStyle:
            DesignTypography.bodySmall(DesignColors.textTertiaryLight),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return DesignColors.primary;
          return DesignColors.textTertiaryLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignColors.primary.withValues(alpha: 0.3);
          }
          return DesignColors.borderLight;
        }),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DesignColors.primary,
        linearTrackColor: DesignColors.borderLight,
        circularTrackColor: DesignColors.borderLight,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: DesignColors.primary,
        unselectedLabelColor: DesignColors.textSecondaryLight,
        labelStyle: DesignTypography.labelLarge(DesignColors.primary),
        unselectedLabelStyle:
            DesignTypography.labelLarge(DesignColors.textSecondaryLight),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: DesignColors.primary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: DesignColors.borderLight,
      ),

      // Text Theme
      textTheme: _buildTextTheme(false),

      // Extensions
      extensions: [
        const FeatureColors(
          vision: DesignColors.vision,
          visionLight: DesignColors.visionLight,
          visionSurface: DesignColors.visionSurface,
          nlp: DesignColors.nlp,
          nlpLight: DesignColors.nlpLight,
          nlpSurface: DesignColors.nlpSurface,
          generative: DesignColors.generative,
          generativeLight: DesignColors.generativeLight,
          generativeSurface: DesignColors.generativeSurface,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: DesignColors.accent,
      onPrimary: DesignColors.primary,
      primaryContainer: DesignColors.accentDark,
      onPrimaryContainer: Colors.white,
      secondary: DesignColors.secondaryLight,
      onSecondary: DesignColors.primary,
      secondaryContainer: DesignColors.secondary,
      onSecondaryContainer: Colors.white,
      tertiary: DesignColors.accent,
      onTertiary: DesignColors.primary,
      surface: DesignColors.surfaceDark,
      onSurface: DesignColors.textPrimaryDark,
      surfaceContainerHighest: DesignColors.cardDark,
      error: DesignColors.error,
      onError: Colors.white,
      outline: DesignColors.borderDark,
      outlineVariant: DesignColors.borderSubtleDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DesignColors.backgroundDark,
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: DesignColors.surfaceDark,
        foregroundColor: DesignColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle:
            DesignTypography.titleLarge(DesignColors.textPrimaryDark),
        iconTheme: const IconThemeData(
          color: DesignColors.textPrimaryDark,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: DesignColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusLg,
          side: const BorderSide(color: DesignColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignColors.accent,
          foregroundColor: DesignColors.primary,
          disabledBackgroundColor: DesignColors.textDisabledDark,
          disabledForegroundColor: Colors.white54,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: DesignRadius.radiusMd,
          ),
          elevation: 0,
          textStyle: DesignTypography.button(DesignColors.primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: DesignRadius.radiusMd,
          ),
          side: const BorderSide(color: DesignColors.accent, width: 1.5),
          textStyle: DesignTypography.button(DesignColors.accent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: DesignTypography.button(DesignColors.accent),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: DesignColors.textSecondaryDark,
          padding: const EdgeInsets.all(10),
          minimumSize: const Size(40, 40),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DesignColors.accent,
        foregroundColor: DesignColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusLg,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignColors.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DesignRadius.radiusMd,
          borderSide: const BorderSide(color: DesignColors.error),
        ),
        hintStyle: DesignTypography.bodyMedium(DesignColors.textTertiaryDark),
        labelStyle: DesignTypography.bodyMedium(DesignColors.textSecondaryDark),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: DesignColors.surfaceDark,
        selectedItemColor: DesignColors.accent,
        unselectedItemColor: DesignColors.textTertiaryDark,
        selectedLabelStyle: DesignTypography.labelSmall(DesignColors.accent),
        unselectedLabelStyle:
            DesignTypography.labelSmall(DesignColors.textTertiaryDark),
        elevation: 8,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: DesignSpacing.bottomNavHeight,
        backgroundColor: DesignColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: DesignColors.accent.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: DesignColors.accent, size: 24);
          }
          return const IconThemeData(
              color: DesignColors.textTertiaryDark, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTypography.labelSmall(DesignColors.accent);
          }
          return DesignTypography.labelSmall(DesignColors.textTertiaryDark);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DesignColors.surfaceDark,
        selectedColor: DesignColors.accent.withValues(alpha: 0.2),
        disabledColor: DesignColors.borderSubtleDark,
        labelStyle: DesignTypography.labelMedium(DesignColors.textPrimaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusFull,
          side: const BorderSide(color: DesignColors.borderDark),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DesignColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusXl,
        ),
        titleTextStyle:
            DesignTypography.headlineSmall(DesignColors.textPrimaryDark),
        contentTextStyle:
            DesignTypography.bodyMedium(DesignColors.textSecondaryDark),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DesignColors.cardDark,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: DesignColors.cardDark,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignRadius.xl),
          ),
        ),
        dragHandleColor: DesignColors.borderDark,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DesignColors.accent,
        contentTextStyle: DesignTypography.bodyMedium(DesignColors.primary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusMd,
        ),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: DesignColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: DesignSpacing.listItemPadding,
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        shape: RoundedRectangleBorder(
          borderRadius: DesignRadius.radiusMd,
        ),
        titleTextStyle:
            DesignTypography.titleSmall(DesignColors.textPrimaryDark),
        subtitleTextStyle:
            DesignTypography.bodySmall(DesignColors.textSecondaryDark),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DesignColors.accent;
          return DesignColors.textTertiaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignColors.accent.withValues(alpha: 0.3);
          }
          return DesignColors.borderDark;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DesignColors.accent,
        linearTrackColor: DesignColors.borderDark,
        circularTrackColor: DesignColors.borderDark,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: DesignColors.accent,
        unselectedLabelColor: DesignColors.textSecondaryDark,
        labelStyle: DesignTypography.labelLarge(DesignColors.accent),
        unselectedLabelStyle:
            DesignTypography.labelLarge(DesignColors.textSecondaryDark),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: DesignColors.accent, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: DesignColors.borderDark,
      ),
      textTheme: _buildTextTheme(true),
      extensions: [
        const FeatureColors(
          vision: DesignColors.visionLight,
          visionLight: DesignColors.vision,
          visionSurface: Color(0xFF1A1025),
          nlp: DesignColors.nlpLight,
          nlpLight: DesignColors.nlp,
          nlpSurface: Color(0xFF0A1F17),
          generative: DesignColors.generativeLight,
          generativeLight: DesignColors.generative,
          generativeSurface: Color(0xFF1F0A0A),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TEXT THEME BUILDER
  // ══════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme(bool isDark) {
    final primaryColor =
        isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight;
    final secondaryColor = isDark
        ? DesignColors.textSecondaryDark
        : DesignColors.textSecondaryLight;

    return TextTheme(
      displayLarge: DesignTypography.displayLarge(primaryColor),
      displayMedium: DesignTypography.displayMedium(primaryColor),
      displaySmall: DesignTypography.displaySmall(primaryColor),
      headlineLarge: DesignTypography.headlineLarge(primaryColor),
      headlineMedium: DesignTypography.headlineMedium(primaryColor),
      headlineSmall: DesignTypography.headlineSmall(primaryColor),
      titleLarge: DesignTypography.titleLarge(primaryColor),
      titleMedium: DesignTypography.titleMedium(primaryColor),
      titleSmall: DesignTypography.titleSmall(primaryColor),
      bodyLarge: DesignTypography.bodyLarge(primaryColor),
      bodyMedium: DesignTypography.bodyMedium(secondaryColor),
      bodySmall: DesignTypography.bodySmall(secondaryColor),
      labelLarge: DesignTypography.labelLarge(primaryColor),
      labelMedium: DesignTypography.labelMedium(secondaryColor),
      labelSmall: DesignTypography.labelSmall(secondaryColor),
    );
  }
}

/// Theme extension for feature-specific colors
@immutable
class FeatureColors extends ThemeExtension<FeatureColors> {
  final Color vision;
  final Color visionLight;
  final Color visionSurface;
  final Color nlp;
  final Color nlpLight;
  final Color nlpSurface;
  final Color generative;
  final Color generativeLight;
  final Color generativeSurface;

  const FeatureColors({
    required this.vision,
    required this.visionLight,
    required this.visionSurface,
    required this.nlp,
    required this.nlpLight,
    required this.nlpSurface,
    required this.generative,
    required this.generativeLight,
    required this.generativeSurface,
  });

  @override
  FeatureColors copyWith({
    Color? vision,
    Color? visionLight,
    Color? visionSurface,
    Color? nlp,
    Color? nlpLight,
    Color? nlpSurface,
    Color? generative,
    Color? generativeLight,
    Color? generativeSurface,
  }) {
    return FeatureColors(
      vision: vision ?? this.vision,
      visionLight: visionLight ?? this.visionLight,
      visionSurface: visionSurface ?? this.visionSurface,
      nlp: nlp ?? this.nlp,
      nlpLight: nlpLight ?? this.nlpLight,
      nlpSurface: nlpSurface ?? this.nlpSurface,
      generative: generative ?? this.generative,
      generativeLight: generativeLight ?? this.generativeLight,
      generativeSurface: generativeSurface ?? this.generativeSurface,
    );
  }

  @override
  FeatureColors lerp(FeatureColors? other, double t) {
    if (other == null) return this;
    return FeatureColors(
      vision: Color.lerp(vision, other.vision, t)!,
      visionLight: Color.lerp(visionLight, other.visionLight, t)!,
      visionSurface: Color.lerp(visionSurface, other.visionSurface, t)!,
      nlp: Color.lerp(nlp, other.nlp, t)!,
      nlpLight: Color.lerp(nlpLight, other.nlpLight, t)!,
      nlpSurface: Color.lerp(nlpSurface, other.nlpSurface, t)!,
      generative: Color.lerp(generative, other.generative, t)!,
      generativeLight: Color.lerp(generativeLight, other.generativeLight, t)!,
      generativeSurface:
          Color.lerp(generativeSurface, other.generativeSurface, t)!,
    );
  }
}

/// Extension to easily access feature colors from context
extension FeatureColorsExtension on BuildContext {
  FeatureColors get featureColors => Theme.of(this).extension<FeatureColors>()!;
}
