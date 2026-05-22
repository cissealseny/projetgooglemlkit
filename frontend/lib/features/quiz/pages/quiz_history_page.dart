import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/di/injection.dart';
import '../repository/quiz_repository.dart';
import '../models/quiz_models.dart';
import 'quiz_result_page.dart';

class QuizHistoryPage extends StatelessWidget {
  final List<QuizSummary> quizzes;

  const QuizHistoryPage({super.key, required this.quizzes});

  Future<void> _openLatestAttempt(
    BuildContext context,
    QuizSummary summary,
  ) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = getIt<QuizRepository>();
      final quiz = await repository
          .getQuiz(summary.id)
          .timeout(const Duration(seconds: 20));
      final result = await repository
          .getLatestAttempt(summary.id)
          .timeout(const Duration(seconds: 20));

      if (!context.mounted) return;
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      context.push(
        '/ai/quiz/result',
        extra: QuizResultArgs(quiz: quiz, result: result),
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      final status = e.response?.statusCode;
      final message = status == 404
          ? 'Aucune tentative pour ce quiz.'
          : 'Erreur lors du chargement de la tentative.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on TimeoutException {
      if (!context.mounted) return;
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Temps d\'attente depasse.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors du chargement de la tentative.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          DesignSpacing.md,
          DesignSpacing.md,
          DesignSpacing.md,
          DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
        ),
        itemCount: quizzes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return InkWell(
            borderRadius: DesignRadius.radiusLg,
            onTap: () => _openLatestAttempt(context, quiz),
            child: PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: DesignTypography.titleSmall(isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${quiz.topic} - ${quiz.questionCount} questions',
                    style: DesignTypography.bodySmall(isDark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
