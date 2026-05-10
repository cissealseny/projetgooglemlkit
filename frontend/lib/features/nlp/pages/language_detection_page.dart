import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../bloc/nlp_bloc.dart';

class LanguageDetectionPage extends StatelessWidget {
  const LanguageDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NLPBloc>(
      create: (_) => getIt<NLPBloc>(),
      child: const _LanguageDetectionView(),
    );
  }
}

class _LanguageDetectionView extends StatefulWidget {
  const _LanguageDetectionView();

  @override
  State<_LanguageDetectionView> createState() => _LanguageDetectionViewState();
}

class _LanguageDetectionViewState extends State<_LanguageDetectionView> {
  final _textController = TextEditingController();
  bool _useLocalProcessing = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détection de langue')),
      body: BlocBuilder<NLPBloc, NLPState>(
        builder: (context, state) {
          final possibleLanguages = _extractLanguageCandidates(state.result);

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
                          'Texte à analyser',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _textController,
                          maxLines: 5,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Collez ou saisissez votre texte...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    title: const Text('Traitement local (ML Kit)'),
                    subtitle: Text(
                      _useLocalProcessing
                          ? 'Analyse sur appareil (hors ligne possible)'
                          : 'Analyse sur serveur (API backend)',
                    ),
                    value: _useLocalProcessing,
                    onChanged: (value) {
                      setState(() {
                        _useLocalProcessing = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: state.status != NLPStatus.loading &&
                          _textController.text.trim().isNotEmpty
                      ? _detectLanguage
                      : null,
                  icon: state.status == NLPStatus.loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.language),
                  label: const Text('Détecter'),
                ),
                const SizedBox(height: 24),
                if (state.status == NLPStatus.success && state.result != null)
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Langue détectée: ${state.result!['language'] ?? 'inconnue'}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (possibleLanguages.isNotEmpty) ...[
                            const Divider(),
                            Text(
                              'Probabilités',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            ...possibleLanguages.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(item['language'] ?? '-'),
                                    ),
                                    Text(
                                      _formatConfidence(item['confidence']),
                                    ),
                                  ],
                                ),
                              ),
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
            ),
          );
        },
      ),
    );
  }

  void _detectLanguage() {
    context.read<NLPBloc>().add(
          DetectLanguage(
            text: _textController.text.trim(),
            useLocal: _useLocalProcessing,
          ),
        );
  }

  List<Map<String, dynamic>> _extractLanguageCandidates(
    Map<String, dynamic>? result,
  ) {
    if (result == null) return const [];

    final possible = result['possibleLanguages'];
    if (possible is List) {
      return possible
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final probabilities = result['probabilities'];
    if (probabilities is List) {
      return probabilities
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return const [];
  }

  String _formatConfidence(dynamic value) {
    if (value is num) {
      return '${(value * 100).toStringAsFixed(1)}%';
    }
    return '-';
  }
}
