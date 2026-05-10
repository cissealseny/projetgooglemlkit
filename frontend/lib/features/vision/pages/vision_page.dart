import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/widgets/premium_components.dart';

/// Premium Vision Page
class VisionPage extends StatelessWidget {
  const VisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = Theme.of(context).extension<FeatureColors>()!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180 + topPadding,
            floating: false,
            pinned: true,
            backgroundColor: isDark
                ? DesignColors.backgroundDark
                : DesignColors.backgroundLight,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: DesignColors.visionGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: DesignRadius.radiusMd,
                          ),
                          child: const Icon(Icons.visibility_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text('Vision',
                            style:
                                DesignTypography.headlineLarge(Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: DesignSpacing.md,
              right: DesignSpacing.md,
              top: DesignSpacing.lg,
              bottom: DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CameraCard(
                    color: features.vision,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.go('/vision/realtime');
                    }),
                const SizedBox(height: 24),
                SectionHeader(
                    title: 'Fonctionnalités', padding: EdgeInsets.zero),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.text_fields_rounded,
                    title: 'Reconnaissance de texte',
                    subtitle: 'OCR',
                    color: features.vision,
                    onTap: () => context.go('/vision/text-recognition')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.face_rounded,
                    title: 'Détection de visages',
                    subtitle: 'Analyse faciale',
                    color: features.vision,
                    onTap: () => context.go('/vision/face-detection')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.category_rounded,
                    title: 'Détection d\'objets',
                    subtitle: 'Identification',
                    color: features.vision,
                    onTap: () => context.go('/vision/object-detection')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Scan de codes-barres',
                    subtitle: 'QR & Barcodes',
                    color: features.vision,
                    onTap: () => context.go('/vision/barcode-scan')),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _CameraCard({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: DesignRadius.radiusXl,
          boxShadow: DesignColors.shadowColored(color),
        ),
        child: Row(
          children: [
            Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: DesignRadius.radiusLg),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 32)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Ouvrir la caméra',
                      style: DesignTypography.titleLarge(Colors.white)),
                  const SizedBox(height: 4),
                  Text('Analyser en temps réel',
                      style: DesignTypography.bodySmall(
                          Colors.white.withValues(alpha: 0.8))),
                ])),
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: DesignRadius.radiusFull),
                child:
                    Icon(Icons.arrow_forward_rounded, color: color, size: 20)),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _FeatureTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: DesignRadius.radiusMd),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: DesignTypography.titleSmall(isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: DesignTypography.bodySmall(isDark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight)),
              ])),
          Icon(Icons.chevron_right_rounded,
              color: isDark
                  ? DesignColors.textTertiaryDark
                  : DesignColors.textTertiaryLight),
        ]),
      ),
    );
  }
}
