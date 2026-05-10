import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/widgets/premium_components.dart';

/// Premium NLP Page
class NLPPage extends StatelessWidget {
  const NLPPage({super.key});

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
                    const BoxDecoration(gradient: DesignColors.nlpGradient),
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
                          child: const Icon(Icons.translate_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text('Langage',
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
                _InputCard(color: features.nlp, isDark: isDark),
                const SizedBox(height: 24),
                SectionHeader(
                    title: 'Fonctionnalités', padding: EdgeInsets.zero),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.g_translate_rounded,
                    title: 'Traduction',
                    subtitle: 'Traduire entre langues',
                    color: features.nlp,
                    onTap: () => context.go('/nlp/translation')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    title: 'Analyse de sentiment',
                    subtitle: 'Détecter les émotions',
                    color: features.nlp,
                    onTap: () => context.go('/nlp/sentiment')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.label_rounded,
                    title: 'Extraction d\'entités',
                    subtitle: 'Noms, lieux, dates',
                    color: features.nlp,
                    onTap: () => context.go('/nlp/entity-extraction')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.language_rounded,
                    title: 'Détection de langue',
                    subtitle: 'Identifier la langue',
                    color: features.nlp,
                    onTap: () => context.go('/nlp/language-detection')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.short_text_rounded,
                    title: 'Résumé',
                    subtitle: 'Synthèse de longs textes',
                    color: features.nlp,
                    onTap: () => context.go('/nlp/summarization')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.category_rounded,
                    title: 'Classification',
                    subtitle: 'Classement thématique',
                    color: features.nlp,
                    onTap: () => context.go('/nlp/classification')),
                const SizedBox(height: 12),
                _FeatureTile(
                    icon: Icons.quickreply_rounded,
                    title: 'Smart Reply',
                    subtitle: 'Suggestions de réponses',
                    color: features.nlp,
                    onTap: () => context.go('/nlp/smart-reply')),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Color color;
  final bool isDark;
  const _InputCard({required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
        borderRadius: DesignRadius.radiusXl,
        boxShadow: DesignColors.shadowColored(color),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: DesignRadius.radiusMd),
                child: const Icon(Icons.mic_rounded,
                    color: Colors.white, size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Saisie vocale',
                      style: DesignTypography.titleMedium(Colors.white)),
                  Text('Parlez pour analyser',
                      style: DesignTypography.bodySmall(
                          Colors.white.withValues(alpha: 0.8))),
                ])),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: DesignRadius.radiusMd,
            ),
            child: Row(children: [
              Expanded(
                  child: Text('Tapez ou parlez...',
                      style: DesignTypography.bodyMedium(
                          Colors.white.withValues(alpha: 0.7)))),
              const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ]),
          ),
        ],
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
