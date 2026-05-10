import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../bloc/nlp_bloc.dart';
import '../utils/nlp_provider_prefs.dart';

class TranslationPage extends StatelessWidget {
  const TranslationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NLPBloc>(
      create: (_) => getIt<NLPBloc>(),
      child: const _TranslationView(),
    );
  }
}

class _TranslationView extends StatefulWidget {
  const _TranslationView();

  @override
  State<_TranslationView> createState() => _TranslationViewState();
}

class _TranslationViewState extends State<_TranslationView> {
  final _textController = TextEditingController();
  String _sourceLang = 'en';
  String _targetLang = 'fr';
  bool _useLocalProcessing = true;
  String _remoteProvider = 'huggingface';

  final _providers = const [
    {'id': 'auto', 'label': 'Auto'},
    {'id': 'huggingface', 'label': 'Hugging Face'},
    {'id': 'google', 'label': 'Google'},
  ];

  final _languages = {
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ar': 'العربية',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
  };

  @override
  void initState() {
    super.initState();
    _remoteProvider = NlpProviderPrefs.getProvider();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traduction')),
      body: BlocBuilder<NLPBloc, NLPState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Language Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LanguageDropdown(
                            label: 'De',
                            value: _sourceLang,
                            languages: _languages,
                            onChanged: (value) {
                              setState(() {
                                _sourceLang = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () {
                            setState(() {
                              final temp = _sourceLang;
                              _sourceLang = _targetLang;
                              _targetLang = temp;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LanguageDropdown(
                            label: 'Vers',
                            value: _targetLang,
                            languages: _languages,
                            onChanged: (value) {
                              setState(() {
                                _targetLang = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Text
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Texte à traduire',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _textController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Entrez le texte à traduire...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Processing Mode Toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Traduction locale (ML Kit)'),
                    subtitle: Text(
                      _useLocalProcessing
                          ? 'Traitement sur l\'appareil (hors ligne)'
                          : 'Traitement sur le serveur (plus précis)',
                    ),
                    value: _useLocalProcessing,
                    onChanged: (value) {
                      setState(() {
                        _useLocalProcessing = value;
                      });
                    },
                  ),
                ),
                if (!_useLocalProcessing) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded),
                          const SizedBox(width: 10),
                          const Text('Provider serveur:'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _remoteProvider,
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
                                setState(() => _remoteProvider = value);
                                NlpProviderPrefs.setProvider(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Translate Button
                ElevatedButton.icon(
                  onPressed: state.status != NLPStatus.loading &&
                          _textController.text.isNotEmpty
                      ? _translate
                      : null,
                  icon: state.status == NLPStatus.loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate),
                  label: const Text('Traduire'),
                ),
                const SizedBox(height: 24),

                // Result
                if (state.status == NLPStatus.success &&
                    state.result != null) ...[
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Traduction',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  // Copy to clipboard
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          SelectableText(
                            state.result!['translatedText'] ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (state.result!['warning'] != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.orange[800],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.result!['warning'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.orange[900]),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                          if (state.result!['processingTime'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Temps: ${state.result!['processingTime'].toStringAsFixed(2)}s',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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

  void _translate() {
    if (_textController.text.isNotEmpty) {
      context.read<NLPBloc>().add(
            TranslateText(
              text: _textController.text,
              sourceLang: _sourceLang,
              targetLang: _targetLang,
              useLocal: _useLocalProcessing,
              provider: _remoteProvider,
            ),
          );
    }
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> languages;
  final ValueChanged<String?> onChanged;

  const _LanguageDropdown({
    required this.label,
    required this.value,
    required this.languages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: languages.entries.map((entry) {
            return DropdownMenuItem(value: entry.key, child: Text(entry.value));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
