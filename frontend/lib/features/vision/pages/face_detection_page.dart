import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../bloc/vision_bloc.dart';

class FaceDetectionPage extends StatelessWidget {
  const FaceDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VisionBloc>(
      create: (_) => getIt<VisionBloc>(),
      child: const _FaceDetectionView(),
    );
  }
}

class _FaceDetectionView extends StatefulWidget {
  const _FaceDetectionView();

  @override
  State<_FaceDetectionView> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<_FaceDetectionView> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détection de visages')),
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
                                  Icons.face,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sélectionnez une image avec des visages',
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
                          ? _detectFaces
                          : null,
                  child: state.status == VisionStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Détecter les visages'),
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
                                '${state.result!['count'] ?? 0} visage(s) détecté(s)',
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
                          if (state.result!['faces'] != null)
                            ...List.generate(
                              (state.result!['faces'] as List).length,
                              (index) {
                                final face = state.result!['faces'][index];
                                return _buildFaceCard(context, face, index);
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

  Widget _buildFaceCard(
    BuildContext context,
    Map<String, dynamic> face,
    int index,
  ) {
    final smiling = face['smilingProbability'];
    final leftEye = face['leftEyeOpenProbability'];
    final rightEye = face['rightEyeOpenProbability'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visage ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (smiling != null) _buildProbabilityRow('Sourire', smiling),
          if (leftEye != null)
            _buildProbabilityRow('Œil gauche ouvert', leftEye),
          if (rightEye != null)
            _buildProbabilityRow('Œil droit ouvert', rightEye),
        ],
      ),
    );
  }

  Widget _buildProbabilityRow(String label, double? probability) {
    if (probability == null) return const SizedBox.shrink();

    final percent = (probability * 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: probability,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 8),
          Text('$percent%'),
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

  void _detectFaces() {
    if (_imagePath != null) {
      context.read<VisionBloc>().add(DetectFaces(imagePath: _imagePath!));
    }
  }
}
