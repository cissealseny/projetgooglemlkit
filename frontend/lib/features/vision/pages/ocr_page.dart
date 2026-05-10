import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../bloc/vision_bloc.dart';

class OCRPage extends StatelessWidget {
  const OCRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VisionBloc>(
      create: (_) => getIt<VisionBloc>(),
      child: const _OCRView(),
    );
  }
}

class _OCRView extends StatefulWidget {
  const _OCRView();

  @override
  State<_OCRView> createState() => _OCRViewState();
}

class _OCRViewState extends State<_OCRView> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  bool _useLocalProcessing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR - Reconnaissance de texte')),
      body: BlocBuilder<VisionBloc, VisionState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Preview
                Card(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[200],
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sélectionnez une image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Image Source Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Caméra'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galerie'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Processing Mode Toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Traitement local (ML Kit)'),
                    subtitle: Text(
                      _useLocalProcessing
                          ? 'Traitement sur l\'appareil'
                          : 'Traitement sur le serveur',
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

                // Analyze Button
                ElevatedButton(
                  onPressed:
                      _imagePath != null && state.status != VisionStatus.loading
                          ? _performOCR
                          : null,
                  child: state.status == VisionStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Analyser'),
                ),
                const SizedBox(height: 24),

                // Results
                if (state.status == VisionStatus.success &&
                    state.result != null) ...[
                  Text(
                    'Résultat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Temps: ${state.result!['processingTime']?.toStringAsFixed(2)}s',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Texte détecté:',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            state.result!['text'] ?? 'Aucun texte détecté',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (state.status == VisionStatus.failure) ...[
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      if (!mounted) return;
      setState(() {
        _imagePath = image.path;
      });
      context.read<VisionBloc>().add(ClearVisionResult());
    }
  }

  void _performOCR() {
    if (_imagePath != null) {
      context.read<VisionBloc>().add(
            PerformOCR(imagePath: _imagePath!, useLocal: _useLocalProcessing),
          );
    }
  }
}
