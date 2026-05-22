import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/widgets/premium_components.dart';
import '../models/quiz_models.dart';

class QuizResultArgs {
  final Quiz quiz;
  final QuizResult result;

  QuizResultArgs({required this.quiz, required this.result});
}

class QuizResultPage extends StatelessWidget {
  final Quiz quiz;
  final QuizResult result;

  const QuizResultPage({super.key, required this.quiz, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = Theme.of(context).extension<FeatureColors>()!;
    final double scorePercent = result.maxScore == 0
        ? 0.0
        : (result.score / result.maxScore).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultats du quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignSpacing.md,
          DesignSpacing.lg,
          DesignSpacing.md,
          DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: DesignColors.quizGradient,
              borderRadius: DesignRadius.radiusXl,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: scorePercent,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Text(
                        '${(scorePercent * 100).round()}%',
                        style: DesignTypography.titleLarge(Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quiz.title,
                          style: DesignTypography.titleLarge(Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        '${result.score.toStringAsFixed(1)} / ${result.maxScore} points',
                        style: DesignTypography.bodySmall(
                            Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Details', padding: EdgeInsets.zero),
          const SizedBox(height: 12),
          ...result.results.map((item) {
            final correctColor =
                item.isCorrect ? DesignColors.success : DesignColors.error;

            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: correctColor.withValues(alpha: 0.12),
                      borderRadius: DesignRadius.radiusMd,
                    ),
                    child: Icon(
                      item.isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: correctColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isCorrect ? 'Bonne reponse' : 'A revoir',
                          style: DesignTypography.titleSmall(isDark
                              ? DesignColors.textPrimaryDark
                              : DesignColors.textPrimaryLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.feedback.isNotEmpty
                              ? item.feedback
                              : 'Reponse attendue: ${item.correctAnswer}',
                          style: DesignTypography.bodySmall(isDark
                              ? DesignColors.textSecondaryDark
                              : DesignColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.refresh_rounded, color: features.quiz),
              label: Text('Rejouer',
                  style: DesignTypography.button(features.quiz)),
              onPressed: () => context.go('/ai/quiz'),
            ),
          ),
        ],
      ),
    );
  }
}
