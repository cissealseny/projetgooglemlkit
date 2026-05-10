import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../bloc/nlp_bloc.dart';
import '../utils/nlp_provider_prefs.dart';

class SummarizationPage extends StatelessWidget {
  const SummarizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NLPBloc>(
      create: (_) => getIt<NLPBloc>(),
      child: const _SummarizationView(),
    );
  }
}

class _SummarizationView extends StatefulWidget {
  const _SummarizationView();

  @override
  State<_SummarizationView> createState() => _SummarizationViewState();
}

class _SummarizationViewState extends State<_SummarizationView> {
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
      appBar: AppBar(title: const Text('Resume de texte')),
      body: BlocBuilder<NLPBloc, NLPState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Texte a resumer',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 8,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Collez un texte long...',
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
                    child: DropdownButtonFormField<String>(
                      initialValue: _provider,
                      decoration: const InputDecoration(
                        labelText: 'Provider',
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
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: state.status != NLPStatus.loading &&
                          _textController.text.trim().isNotEmpty
                      ? _summarize
                      : null,
                  icon: state.status == NLPStatus.loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.short_text_rounded),
                  label: const Text('Generer le resume'),
                ),
                const SizedBox(height: 20),
                if (state.status == NLPStatus.success && state.result != null)
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resume',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                              (state.result!['summary'] ?? '').toString()),
                          if (state.result!['provider_used'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Provider: ${state.result!['provider_used']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (state.status == NLPStatus.failure)
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        state.error ?? 'Une erreur est survenue',
                        style: const TextStyle(color: Colors.red),
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

  void _summarize() {
    context.read<NLPBloc>().add(
          SummarizeText(
            text: _textController.text.trim(),
            provider: _provider,
          ),
        );
  }
}
