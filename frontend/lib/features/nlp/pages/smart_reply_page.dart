import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../bloc/nlp_bloc.dart';

class SmartReplyPage extends StatelessWidget {
  const SmartReplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NLPBloc>(
      create: (_) => getIt<NLPBloc>(),
      child: const _SmartReplyView(),
    );
  }
}

class _SmartReplyView extends StatefulWidget {
  const _SmartReplyView();

  @override
  State<_SmartReplyView> createState() => _SmartReplyViewState();
}

class _SmartReplyViewState extends State<_SmartReplyView> {
  final _localMessageController = TextEditingController();
  final _remoteMessageController = TextEditingController();

  @override
  void dispose() {
    _localMessageController.dispose();
    _remoteMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Reply')),
      body: BlocBuilder<NLPBloc, NLPState>(
        builder: (context, state) {
          final suggestions =
              (state.result?['suggestions'] as List?) ?? const [];
          final status = state.result?['status']?.toString();
          final info = state.result?['info']?.toString();

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
                          'Message précédent (vous)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _localMessageController,
                          maxLines: 2,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Optionnel',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Dernier message reçu',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _remoteMessageController,
                          maxLines: 3,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Ex: Tu es dispo à 19h ?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: state.status != NLPStatus.loading &&
                          _remoteMessageController.text.trim().isNotEmpty
                      ? _generateReplies
                      : null,
                  icon: state.status == NLPStatus.loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.quickreply),
                  label: const Text('Suggérer des réponses'),
                ),
                const SizedBox(height: 24),
                if (state.status == NLPStatus.success)
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggestions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (suggestions.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Aucune suggestion disponible.'),
                                if (status != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Statut ML Kit: $status'),
                                ],
                                if (info != null && info.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(info),
                                ],
                              ],
                            )
                          else
                            ...suggestions.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(item.toString()),
                                ),
                              ),
                            ),
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

  void _generateReplies() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversation = <Map<String, dynamic>>[];

    if (_localMessageController.text.trim().isNotEmpty) {
      conversation.add({
        'isLocalUser': true,
        'text': _localMessageController.text.trim(),
        'timestamp': now - 60 * 1000,
      });
    }

    conversation.add({
      'isLocalUser': false,
      'text': _remoteMessageController.text.trim(),
      'timestamp': now,
      'userId': 'contact',
    });

    context.read<NLPBloc>().add(
          GenerateSmartReplies(conversation: conversation),
        );
  }
}
