import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../bloc/nlp_bloc.dart';
import '../utils/nlp_provider_prefs.dart';

class ClassificationPage extends StatelessWidget {
  const ClassificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NLPBloc>(
      create: (_) => getIt<NLPBloc>(),
      child: const _ClassificationView(),
    );
  }
}

class _ClassificationView extends StatefulWidget {
  const _ClassificationView();

  @override
  State<_ClassificationView> createState() => _ClassificationViewState();
}

class _ClassificationViewState extends State<_ClassificationView> {
  final _textController = TextEditingController();
  final _categoriesController = TextEditingController();
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
    _categoriesController.text = 'restaurant,cafe,hotel,transport,prix,service';
  }

  @override
  void dispose() {
    _textController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classification de texte')),
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
                          'Texte a classer',
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
                            hintText:
                                'Ex: Le service etait rapide mais un peu cher',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _categoriesController,
                          decoration: const InputDecoration(
                            labelText: 'Categories (separees par des virgules)',
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
                      ? _classify
                      : null,
                  icon: state.status == NLPStatus.loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.category_rounded),
                  label: const Text('Classer'),
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
                            'Resultat',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (state.result!['categories'] is List)
                            ...List<Map<String, dynamic>>.from(
                              (state.result!['categories'] as List)
                                  .whereType<Map>()
                                  .map((e) => Map<String, dynamic>.from(e)),
                            ).take(6).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Text((item['label'] ?? '')
                                                .toString())),
                                        Text(((item['score'] ?? 0).toString())),
                                      ],
                                    ),
                                  ),
                                )
                          else
                            Text(
                              'Label: ${(state.result!['label'] ?? 'N/A').toString()}',
                            ),
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

  void _classify() {
    final categories = _categoriesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    context.read<NLPBloc>().add(
          ClassifyText(
            text: _textController.text.trim(),
            categories: categories,
            provider: _provider,
          ),
        );
  }
}
