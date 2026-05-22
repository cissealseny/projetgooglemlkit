import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/widgets/premium_components.dart';
import '../bloc/quiz_bloc.dart';
import '../models/quiz_models.dart';
import 'quiz_result_page.dart';

class QuizSessionArgs {
  final Quiz quiz;

  QuizSessionArgs({required this.quiz});
}

class QuizSessionPage extends StatefulWidget {
  final Quiz quiz;

  const QuizSessionPage({super.key, required this.quiz});

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  final Map<int, String> _answers = {};
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitQuiz(BuildContext context) {
    context.read<QuizBloc>().add(
          SubmitQuiz(
            quizId: widget.quiz.id,
            answers: _answers,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = Theme.of(context).extension<FeatureColors>()!;

    return BlocProvider(
      create: (_) => getIt<QuizBloc>(),
      child: BlocConsumer<QuizBloc, QuizState>(
        listener: (context, state) {
          if (state.status == QuizStatus.failure && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (state.status == QuizStatus.submitted && state.result != null) {
            context.push(
              '/ai/quiz/result',
              extra: QuizResultArgs(quiz: widget.quiz, result: state.result!),
            );
          }
        },
        builder: (context, state) {
          final bottomInset = MediaQuery.of(context).viewPadding.bottom;
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.quiz.title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: DesignColors.quizGradient,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(DesignRadius.xl),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: DesignRadius.radiusMd,
                        ),
                        child: const Icon(Icons.quiz_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.quiz.topic,
                                style:
                                    DesignTypography.titleLarge(Colors.white)),
                            Text(
                              '${widget.quiz.questionCount} questions - ${widget.quiz.difficulty.toUpperCase()}',
                              style: DesignTypography.bodySmall(
                                  Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      DesignSpacing.md,
                      DesignSpacing.lg,
                      DesignSpacing.md,
                      DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
                    ),
                    itemCount: widget.quiz.questions.length,
                    itemBuilder: (context, index) {
                      final question = widget.quiz.questions[index];
                      return _QuestionCard(
                        question: question,
                        isDark: isDark,
                        color: features.quiz,
                        answer: _answers[question.id],
                        controller: _getController(question.id),
                        onAnswer: (value) {
                          setState(() => _answers[question.id] = value);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    DesignSpacing.bottomNavHeight + bottomInset + 16,
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: state.status == QuizStatus.submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(state.status == QuizStatus.submitting
                            ? 'Correction...'
                            : 'Valider le quiz'),
                        onPressed: state.status == QuizStatus.submitting
                            ? null
                            : () => _submitQuiz(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TextEditingController _getController(int id) {
    return _controllers.putIfAbsent(id, () => TextEditingController());
  }
}

class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final bool isDark;
  final Color color;
  final String? answer;
  final TextEditingController controller;
  final ValueChanged<String> onAnswer;

  const _QuestionCard({
    required this.question,
    required this.isDark,
    required this.color,
    required this.answer,
    required this.controller,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: DesignRadius.radiusSm,
                ),
                child: Center(
                  child: Text(
                    question.order.toString(),
                    style: DesignTypography.labelLarge(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.prompt,
                  style: DesignTypography.titleSmall(isDark
                      ? DesignColors.textPrimaryDark
                      : DesignColors.textPrimaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (question.type == 'open')
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              onChanged: onAnswer,
              decoration: const InputDecoration(
                hintText: 'Votre reponse...',
              ),
            )
          else
            Column(
              children: question.options.map((option) {
                final isSelected = answer == option;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: DesignRadius.radiusMd,
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.4)
                          : (isDark
                              ? DesignColors.borderDark
                              : DesignColors.borderLight),
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: option,
                    groupValue: answer,
                    onChanged: (value) {
                      if (value == null) return;
                      onAnswer(value);
                    },
                    title: Text(option,
                        style: DesignTypography.bodyMedium(isDark
                            ? DesignColors.textPrimaryDark
                            : DesignColors.textPrimaryLight)),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
