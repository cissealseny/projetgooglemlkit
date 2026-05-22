import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';

class WasteClassificationPage extends StatefulWidget {
  const WasteClassificationPage({super.key});

  @override
  State<WasteClassificationPage> createState() => _WasteClassificationPageState();
}

class _WasteClassificationPageState extends State<WasteClassificationPage> {
  File? _image;
  List<ImageLabel> _labels = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  late final ImageLabeler _imageLabeler;

  @override
  void initState() {
    super.initState();
    // Initialize the image labeler
    final ImageLabelerOptions options =
        ImageLabelerOptions(confidenceThreshold: 0.75);
    _imageLabeler = ImageLabeler(options: options);
  }

  @override
  void dispose() {
    _imageLabeler.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _labels = [];
          _isLoading = true;
        });
        _processImage(_image!);
      }
    } catch (e) {
      // Handle exceptions
      print("Error picking image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage(File image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);
      setState(() {
        _labels = labels;
        _isLoading = false;
      });
    } catch (e) {
      print("Error processing image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interface IA de Classification'),
        backgroundColor: isDark ? DesignColors.backgroundDark : DesignColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: DesignSpacing.md,
              right: DesignSpacing.md,
              top: DesignSpacing.md,
              bottom: DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Action Buttons ---
                _buildActionButtons(),
                const SizedBox(height: 24),

                // --- Image Display ---
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_image != null)
                  _buildImageDisplay()
                else
                  _buildImagePlaceholder(),
                
                const SizedBox(height: 24),

                // --- Results ---
                if (_labels.isNotEmpty) _buildResults()

              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Caméra'),
             style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: DottedBorder(
        color: DesignColors.textSecondaryLight,
        strokeWidth: 2,
        dashPattern: const [8, 4],
        radius: const Radius.circular(DesignRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: DesignColors.backgroundDark.withOpacity(0.2),
            borderRadius: DesignRadius.radiusLg,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_search_rounded,
                  size: 64,
                  color: DesignColors.textSecondaryLight,
                ),
                SizedBox(height: 16),
                Text(
                  'Prendre ou uploader une photo',
                  style: TextStyle(color: DesignColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return ClipRRect(
      borderRadius: DesignRadius.radiusLg,
      child: Image.file(
        _image!,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Widget _buildResults() {
    // For now, just display the first label
    final label = _labels.first;
    final category = label.label;
    final confidence = (label.confidence * 100).toStringAsFixed(1);
    final price = _getEstimatedPrice(category);
    final advice = _getRecyclingAdvice(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Résultat de l\'IA',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ResultRow(
                icon: Icons.category_rounded,
                label: 'Prédiction',
                value: category,
              ),
              const SizedBox(height: 12),
              _ResultRow(
                icon: Icons.percent_rounded,
                label: 'Confiance',
                value: '$confidence%',
              ),
              const SizedBox(height: 12),
              _ResultRow(
                icon: Icons.price_change_rounded,
                label: 'Prix Estimé',
                value: price,
                valueColor: DesignColors.ecoSmart,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Conseils de Recyclage',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: DesignColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  advice,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getEstimatedPrice(String category) {
    // Placeholder logic
    switch (category.toLowerCase()) {
      case 'plastic':
      case 'plastique':
        return '~0.800 TND / kg';
      case 'glass':
      case 'verre':
        return '~0.300 TND / kg';
      case 'metal':
        return '~1.200 TND / kg';
      case 'cardboard':
      case 'carton':
        return '~0.500 TND / kg';
      case 'electronics':
      case 'électronique':
        return 'Variable';
      default:
        return 'N/A';
    }
  }

  String _getRecyclingAdvice(String category) {
    // Placeholder logic
    switch (category.toLowerCase()) {
      case 'plastic':
      case 'plastique':
        return 'Videz et rincez les bouteilles. Jetez les bouchons séparément.';
      case 'glass':
      case 'verre':
        return 'Retirez les couvercles et ne cassez pas le verre. Les couleurs peuvent être mélangées.';
      case 'metal':
        return 'Les canettes en aluminium et en acier sont recyclables. Rincez-les.';
      case 'cardboard':
      case 'carton':
        return 'Aplatissez les boîtes pour gagner de la place. Retirez le ruban adhésif.';
      case 'electronics':
      case 'électronique':
        return 'Ne jetez jamais les appareils électroniques à la poubelle. Apportez-les à un point de collecte spécialisé.';
      default:
        return 'Vérifiez les consignes de tri locales pour cet objet.';
    }
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
