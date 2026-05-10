import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';

/// Vision AI Dashboard Page with Modern Card Design
class VisionDashboardPage extends StatefulWidget {
  const VisionDashboardPage({super.key});

  @override
  State<VisionDashboardPage> createState() => _VisionDashboardPageState();
}

class _VisionDashboardPageState extends State<VisionDashboardPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImage;
  String? _selectedFeature;
  bool _isProcessing = false;
  Map<String, dynamic>? _result;

  final List<_VisionFeature> _features = [
    _VisionFeature(
      id: 'ocr',
      title: 'OCR',
      subtitle: 'Text Recognition',
      description: 'Extract text from images, documents, and photos.',
      icon: Icons.document_scanner_rounded,
      color: Color(0xFF8B5CF6),
    ),
    _VisionFeature(
      id: 'face',
      title: 'Face Detection',
      subtitle: 'Facial Analysis',
      description: 'Detect faces and analyze facial features.',
      icon: Icons.face_rounded,
      color: Color(0xFFEC4899),
    ),
    _VisionFeature(
      id: 'object',
      title: 'Object Detection',
      subtitle: 'Object Recognition',
      description: 'Identify and locate objects in images.',
      icon: Icons.category_rounded,
      color: Color(0xFF06B6D4),
    ),
    _VisionFeature(
      id: 'label',
      title: 'Image Labeling',
      subtitle: 'Scene Classification',
      description: 'Automatically label images with descriptive tags.',
      icon: Icons.label_rounded,
      color: Color(0xFFF59E0B),
    ),
    _VisionFeature(
      id: 'barcode',
      title: 'Barcode Scanner',
      subtitle: 'QR & Barcodes',
      description: 'Scan and decode various barcode formats.',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.visionGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.remove_red_eye_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vision AI',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Analyse d\'images avec ML Kit',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildFeatureList(context, isDark),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildWorkArea(context, isDark),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildFeatureGrid(context, isDark),
              const SizedBox(height: 24),
              _buildWorkArea(context, isDark),
            ],
          );
        }
      },
    );
  }

  Widget _buildFeatureList(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Sélectionner une fonctionnalité',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          ..._features
              .map((feature) => _buildFeatureItem(context, feature, isDark)),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final feature = _features[index];
        final isSelected = _selectedFeature == feature.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedFeature = feature.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? feature.color
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: feature.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      feature.icon,
                      color: feature.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, _VisionFeature feature, bool isDark) {
    final isSelected = _selectedFeature == feature.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFeature = feature.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? feature.color.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? feature.color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feature.icon,
                  color: feature.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      feature.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: feature.color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkArea(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  _selectedFeature != null
                      ? _features
                          .firstWhere((f) => f.id == _selectedFeature)
                          .title
                      : 'Espace de travail',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (_selectedImage != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _result = null;
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Effacer'),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildUploadArea(context, isDark),
          ),
          if (_result != null) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildResultArea(context, isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context, bool isDark) {
    if (_selectedImage != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _selectedImage!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedFeature != null && !_isProcessing
                  ? _processImage
                  : null,
              icon: _isProcessing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isProcessing ? 'Traitement...' : 'Analyser'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.cloud_upload_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Glissez une image ici',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'ou cliquez pour sélectionner',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_rounded, size: 18),
              label: const Text('Choisir une image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Résultat',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _result.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _result = null;
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedFeature == null || _selectedImage == null) return;

    setState(() => _isProcessing = true);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
      _result = {
        'feature': _selectedFeature,
        'status': 'success',
        'data': 'Sample result data...',
      };
    });
  }
}

class _VisionFeature {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  _VisionFeature({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
