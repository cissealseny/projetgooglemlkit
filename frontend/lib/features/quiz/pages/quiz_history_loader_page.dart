import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';
import '../repository/quiz_repository.dart';
import '../models/quiz_models.dart';
import 'quiz_history_page.dart';

class QuizHistoryLoaderPage extends StatelessWidget {
  const QuizHistoryLoaderPage({super.key});

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
      body: FutureBuilder<List<QuizSummary>>(
        future: getIt<QuizRepository>().getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement de l\'historique.',
                style: DesignTypography.bodyMedium(isDark
                    ? DesignColors.textSecondaryDark
                    : DesignColors.textSecondaryLight),
              ),
            );
          }

          final quizzes = snapshot.data ?? const <QuizSummary>[];
          if (quizzes.isEmpty) {
            return Center(
              child: PremiumCard(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Aucun quiz enregistre pour le moment.',
                  style: DesignTypography.bodyMedium(isDark
                      ? DesignColors.textSecondaryDark
                      : DesignColors.textSecondaryLight),
                ),
              ),
            );
          }

          return QuizHistoryPage(quizzes: quizzes);
        },
      ),
    );
  }
}
