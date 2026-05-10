import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../bloc/nlp_bloc.dart';
import '../utils/nlp_provider_prefs.dart';

class SentimentPage extends StatelessWidget {
  const SentimentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NLPBloc>(
      create: (_) => getIt<NLPBloc>(),
      child: const _SentimentView(),
    );
  }
}

class _SentimentView extends StatefulWidget {
  const _SentimentView();

  @override
  State<_SentimentView> createState() => _SentimentViewState();
}

class _SentimentViewState extends State<_SentimentView> {
  final _textController = TextEditingController();
  String _provider = 'huggingface';

  final _providers = const [
    {'id': 'auto', 'label': 'Auto'},
    {'id': 'huggingface', 'label': 'Hugging Face'},
    {'id': 'google', 'label': 'Google'},
  ];

  @override
  void initState() {
    super.initState();
    _provider = NlpProviderPrefs.getProvider();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyse de sentiment')),
      body: BlocBuilder<NLPBloc, NLPState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entrez votre texte',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 5,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Écrivez ou collez votre texte ici...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded),
                        const SizedBox(width: 10),
                        const Text('Provider:'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _provider,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _providers
                                .map(
                                  (p) => DropdownMenuItem<String>(
                                    value: p['id']!,
                                    child: Text(p['label']!),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _provider = value);
                              NlpProviderPrefs.setProvider(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Analyze Button
                ElevatedButton(
                  onPressed: state.status != NLPStatus.loading &&
                          _textController.text.trim().isNotEmpty
                      ? _analyzeSentiment
                      : null,
                  child: state.status == NLPStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Analyser le sentiment'),
                ),
                const SizedBox(height: 24),

                // Results
                if (state.status == NLPStatus.success &&
                    state.result != null) ...[
                  _buildSentimentResult(context, state.result!),
                ],

                if (state.status == NLPStatus.failure) ...[
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.error ?? 'Une erreur est survenue',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentimentResult(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    final score = result['score'] as double? ?? 0.0;
    final sentiment = result['sentiment'] as String? ?? 'neutral';
    final magnitude = result['magnitude'] as double? ?? 0.0;

    Color sentimentColor;
    IconData sentimentIcon;
    String sentimentLabel;

    if (sentiment == 'positive' || score > 0.25) {
      sentimentColor = Colors.green;
      sentimentIcon = Icons.sentiment_very_satisfied;
      sentimentLabel = 'Positif';
    } else if (sentiment == 'negative' || score < -0.25) {
      sentimentColor = Colors.red;
      sentimentIcon = Icons.sentiment_very_dissatisfied;
      sentimentLabel = 'Négatif';
    } else {
      sentimentColor = Colors.orange;
      sentimentIcon = Icons.sentiment_neutral;
      sentimentLabel = 'Neutre';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main sentiment
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: sentimentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(sentimentIcon, size: 64, color: sentimentColor),
                  const SizedBox(height: 12),
                  Text(
                    sentimentLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: sentimentColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Metrics
            if (result['provider_used'] != null) ...[
              Row(
                children: [
                  Chip(
                    label: Text('Provider: ${result['provider_used']}'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Score',
                    value: score.toStringAsFixed(2),
                    subtitle: '-1.0 à 1.0',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Magnitude',
                    value: magnitude.toStringAsFixed(2),
                    subtitle: 'Intensité',
                  ),
                ),
              ],
            ),

            if (result['processingTime'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Temps de traitement: ${result['processingTime'].toStringAsFixed(2)}s',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _analyzeSentiment() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      context
          .read<NLPBloc>()
          .add(AnalyzeSentiment(text: text, provider: _provider));
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
