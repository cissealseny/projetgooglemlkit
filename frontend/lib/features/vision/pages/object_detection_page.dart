import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../bloc/vision_bloc.dart';

class ObjectDetectionPage extends StatelessWidget {
  const ObjectDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VisionBloc>(
      create: (_) => getIt<VisionBloc>(),
      child: const _ObjectDetectionView(),
    );
  }
}

class _ObjectDetectionView extends StatefulWidget {
  const _ObjectDetectionView();

  @override
  State<_ObjectDetectionView> createState() => _ObjectDetectionViewState();
}

class _ObjectDetectionViewState extends State<_ObjectDetectionView> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détection d\'objets')),
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
                    height: 300,
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
                                  Icons.category,
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

                // Analyze Button
                ElevatedButton(
                  onPressed:
                      _imagePath != null && state.status != VisionStatus.loading
                          ? _detectObjects
                          : null,
                  child: state.status == VisionStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Détecter les objets'),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${state.result!['count'] ?? 0} objet(s) détecté(s)',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${state.result!['processingTime']?.toStringAsFixed(2)}s',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const Divider(),
                          if (state.result!['objects'] != null)
                            ...List.generate(
                              (state.result!['objects'] as List).length,
                              (index) {
                                final obj = state.result!['objects'][index];
                                return _buildObjectCard(context, obj, index);
                              },
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

  Widget _buildObjectCard(
    BuildContext context,
    Map<String, dynamic> obj,
    int index,
  ) {
    final labels = obj['labels'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objet ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (labels.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.map<Widget>((label) {
                final confidence = ((label['confidence'] ?? 0) * 100).toInt();
                return Chip(
                  label: Text('${label['text']} ($confidence%)'),
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
        ],
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

  void _detectObjects() {
    if (_imagePath != null) {
      context.read<VisionBloc>().add(DetectObjects(imagePath: _imagePath!));
    }
  }
}
