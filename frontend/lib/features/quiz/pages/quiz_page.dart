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
import 'quiz_session_page.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBloc>(
      create: (_) => getIt<QuizBloc>(),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatefulWidget {
  const _QuizView();

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  final _topicController = TextEditingController();
  int _questionCount = 8;
  String _difficulty = 'medium';
  String _language = 'auto';
  String _model = 'ollama:mistral:7b';
  final Set<String> _formats = {'mcq', 'true_false', 'open'};

  final _models = const [
    {'id': 'ollama:mistral:7b', 'name': 'Mistral 7B (Local)'},
    {'id': 'ollama:llama3.2:1b', 'name': 'Llama 3.2 (Leger)'},
    {'id': 'gemini:gemini-2.0-flash', 'name': 'Gemini 2.0 Flash'},
    {'id': 'gemini:gemini-2.5-pro', 'name': 'Gemini 2.5 Pro'},
    {'id': 'gpt:gpt-4o-mini', 'name': 'GPT-4o Mini'},
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez un sujet de quiz.')),
      );
      return;
    }

    context.read<QuizBloc>().add(
          GenerateQuiz(
            topic: topic,
            questionCount: _questionCount,
            difficulty: _difficulty,
            formats: _formats.toList(),
            language: _language,
            model: _model,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = Theme.of(context).extension<FeatureColors>()!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: BlocConsumer<QuizBloc, QuizState>(
        listener: (context, state) {
          if (state.status == QuizStatus.failure && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (state.status == QuizStatus.ready && state.quiz != null) {
            context.push('/ai/quiz/session',
                extra: QuizSessionArgs(quiz: state.quiz!));
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 190 + topPadding,
                floating: false,
                pinned: true,
                backgroundColor: isDark
                    ? DesignColors.backgroundDark
                    : DesignColors.backgroundLight,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                        gradient: DesignColors.quizGradient),
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
                              child: const Icon(Icons.quiz_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 12),
                            Text('Quiz IA',
                                style: DesignTypography.headlineLarge(
                                    Colors.white)),
                            const SizedBox(height: 6),
                            Text('Genere un quiz sur n\'importe quel sujet',
                                style: DesignTypography.bodySmall(
                                    Colors.white.withValues(alpha: 0.8))),
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
                    PremiumCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sujet',
                              style: DesignTypography.titleMedium(isDark
                                  ? DesignColors.textPrimaryDark
                                  : DesignColors.textPrimaryLight)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _topicController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Ex: Marketing digital, Histoire de Rome',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Difficulte',
                              style: DesignTypography.titleMedium(isDark
                                  ? DesignColors.textPrimaryDark
                                  : DesignColors.textPrimaryLight)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['easy', 'medium', 'hard'].map((level) {
                              final selected = _difficulty == level;
                              return ChoiceChip(
                                label: Text(level.toUpperCase()),
                                selected: selected,
                                selectedColor:
                                    features.quiz.withValues(alpha: 0.2),
                                onSelected: (_) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _difficulty = level);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('Nombre de questions',
                              style: DesignTypography.titleMedium(isDark
                                  ? DesignColors.textPrimaryDark
                                  : DesignColors.textPrimaryLight)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _questionCount.toDouble(),
                                  min: 3,
                                  max: 15,
                                  divisions: 12,
                                  activeColor: features.quiz,
                                  label: _questionCount.toString(),
                                  onChanged: (value) {
                                    setState(
                                        () => _questionCount = value.round());
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: features.quiz.withValues(alpha: 0.12),
                                  borderRadius: DesignRadius.radiusMd,
                                ),
                                child: Text(
                                  '$_questionCount',
                                  style: DesignTypography.titleSmall(isDark
                                      ? DesignColors.textPrimaryDark
                                      : DesignColors.textPrimaryLight),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Formats',
                              style: DesignTypography.titleMedium(isDark
                                  ? DesignColors.textPrimaryDark
                                  : DesignColors.textPrimaryLight)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _FormatChip(
                                label: 'QCM',
                                value: 'mcq',
                                selected: _formats.contains('mcq'),
                                color: features.quiz,
                                onTap: _toggleFormat,
                              ),
                              _FormatChip(
                                label: 'Vrai/Faux',
                                value: 'true_false',
                                selected: _formats.contains('true_false'),
                                color: features.quiz,
                                onTap: _toggleFormat,
                              ),
                              _FormatChip(
                                label: 'Libre',
                                value: 'open',
                                selected: _formats.contains('open'),
                                color: features.quiz,
                                onTap: _toggleFormat,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Langue',
                              style: DesignTypography.titleMedium(isDark
                                  ? DesignColors.textPrimaryDark
                                  : DesignColors.textPrimaryLight)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _language,
                            decoration: const InputDecoration(),
                            items: const [
                              DropdownMenuItem(
                                  value: 'auto',
                                  child: Text('Auto (detection)')),
                              DropdownMenuItem(
                                  value: 'fr', child: Text('Francais')),
                              DropdownMenuItem(
                                  value: 'en', child: Text('English')),
                              DropdownMenuItem(
                                  value: 'es', child: Text('Espanol')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _language = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text('Modele IA',
                              style: DesignTypography.titleMedium(isDark
                                  ? DesignColors.textPrimaryDark
                                  : DesignColors.textPrimaryLight)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _model,
                            decoration: const InputDecoration(),
                            items: _models
                                .map((model) => DropdownMenuItem(
                                      value: model['id'] as String,
                                      child: Text(model['name'] as String),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _model = value);
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: state.status == QuizStatus.loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.play_arrow_rounded),
                              label: Text(state.status == QuizStatus.loading
                                  ? 'Generation...'
                                  : 'Lancer le quiz'),
                              onPressed: state.status == QuizStatus.loading
                                  ? null
                                  : () => _submit(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.history_rounded),
                              label: const Text('Voir historique'),
                              onPressed: () => context.push('/ai/quiz/history'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PremiumCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: features.quiz.withValues(alpha: 0.12),
                              borderRadius: DesignRadius.radiusMd,
                            ),
                            child: Icon(Icons.auto_awesome_rounded,
                                color: features.quiz, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Quiz adaptatif, multilingue et prêt à l\'emploi.',
                              style: DesignTypography.bodyMedium(isDark
                                  ? DesignColors.textSecondaryDark
                                  : DesignColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleFormat(String value) {
    setState(() {
      if (_formats.contains(value)) {
        if (_formats.length > 1) {
          _formats.remove(value);
        }
      } else {
        _formats.add(value);
      }
    });
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final void Function(String value) onTap;

  const _FormatChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.2),
      onSelected: (_) {
        HapticFeedback.lightImpact();
        onTap(value);
      },
    );
  }
}
