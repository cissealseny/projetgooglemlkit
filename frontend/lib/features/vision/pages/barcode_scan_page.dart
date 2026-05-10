import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../bloc/vision_bloc.dart';

class BarcodeScanPage extends StatelessWidget {
  const BarcodeScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VisionBloc>(
      create: (_) => getIt<VisionBloc>(),
      child: const _BarcodeScanView(),
    );
  }
}

class _BarcodeScanView extends StatefulWidget {
  const _BarcodeScanView();

  @override
  State<_BarcodeScanView> createState() => _BarcodeScanViewState();
}

class _BarcodeScanViewState extends State<_BarcodeScanView> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de codes-barres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<VisionBloc, VisionState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignColors.vision.withValues(alpha: 0.1),
                        DesignColors.vision.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: DesignRadius.radiusLg,
                    border: Border.all(
                      color: DesignColors.vision.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          color: DesignColors.vision, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scan ML Kit',
                                style: DesignTypography.titleSmall(isDark
                                    ? DesignColors.textPrimaryDark
                                    : DesignColors.textPrimaryLight)),
                            Text('QR Codes, EAN, UPC, Code 128, etc.',
                                style: DesignTypography.bodySmall(isDark
                                    ? DesignColors.textSecondaryDark
                                    : DesignColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Image Preview
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: DesignRadius.radiusLg,
                    color: isDark ? DesignColors.surfaceDark : Colors.grey[100],
                    border: Border.all(
                      color: isDark
                          ? DesignColors.borderDark
                          : DesignColors.borderLight,
                    ),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: DesignRadius.radiusLg,
                          child:
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2_rounded,
                                  size: 64,
                                  color: isDark
                                      ? DesignColors.textTertiaryDark
                                      : Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Prenez une photo ou sélectionnez une image',
                                  style: DesignTypography.bodyMedium(isDark
                                      ? DesignColors.textSecondaryDark
                                      : DesignColors.textSecondaryLight),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Image Source Buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Caméra',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galerie',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Scan Button
                _PrimaryButton(
                  label: 'Scanner',
                  icon: Icons.qr_code_scanner_rounded,
                  isLoading: state.status == VisionStatus.loading,
                  onPressed:
                      _imagePath != null && state.status != VisionStatus.loading
                          ? _scanBarcodes
                          : null,
                ),
                const SizedBox(height: 24),

                // Results
                if (state.status == VisionStatus.success &&
                    state.result != null) ...[
                  _buildResults(context, state.result!, isDark),
                ],

                if (state.status == VisionStatus.failure) ...[
                  _ErrorCard(message: state.error ?? 'Une erreur est survenue'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(
      BuildContext context, Map<String, dynamic> result, bool isDark) {
    final barcodes = result['barcodes'] as List? ?? [];
    final processingTime = result['processingTime'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Résultats',
                style: DesignTypography.titleMedium(isDark
                    ? DesignColors.textPrimaryDark
                    : DesignColors.textPrimaryLight)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DesignColors.vision.withValues(alpha: 0.1),
                borderRadius: DesignRadius.radiusSm,
              ),
              child: Text('${processingTime.toStringAsFixed(2)}s',
                  style: DesignTypography.labelSmall(DesignColors.vision)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (barcodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? DesignColors.surfaceDark : Colors.grey[50],
              borderRadius: DesignRadius.radiusMd,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48,
                      color: isDark
                          ? DesignColors.textTertiaryDark
                          : Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Aucun code-barres détecté',
                      style: DesignTypography.bodyMedium(isDark
                          ? DesignColors.textSecondaryDark
                          : DesignColors.textSecondaryLight)),
                ],
              ),
            ),
          )
        else
          ...barcodes
              .map((barcode) => _BarcodeCard(barcode: barcode, isDark: isDark)),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 1920);
    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
    }
  }

  void _scanBarcodes() {
    HapticFeedback.mediumImpact();
    context.read<VisionBloc>().add(ScanBarcodes(imagePath: _imagePath!));
  }
}

class _BarcodeCard extends StatelessWidget {
  final Map<String, dynamic> barcode;
  final bool isDark;

  const _BarcodeCard({required this.barcode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rawValue = barcode['rawValue'] ?? barcode['displayValue'] ?? 'N/A';
    final format = barcode['format'] ?? 'Unknown';
    final type = barcode['type'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surfaceDark : Colors.white,
        borderRadius: DesignRadius.radiusMd,
        border: Border.all(
          color: isDark ? DesignColors.borderDark : DesignColors.borderLight,
        ),
        boxShadow: DesignColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignColors.vision.withValues(alpha: 0.1),
                  borderRadius: DesignRadius.radiusSm,
                ),
                child: Icon(Icons.qr_code_rounded,
                    color: DesignColors.vision, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(format,
                        style:
                            DesignTypography.labelMedium(DesignColors.vision)),
                    Text(type,
                        style: DesignTypography.bodySmall(isDark
                            ? DesignColors.textSecondaryDark
                            : DesignColors.textSecondaryLight)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded,
                    color: isDark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: rawValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Copié dans le presse-papiers')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              borderRadius: DesignRadius.radiusSm,
            ),
            child: SelectableText(
              rawValue,
              style: DesignTypography.bodyMedium(isDark
                  ? DesignColors.textPrimaryDark
                  : DesignColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? DesignColors.surfaceDark : Colors.white,
      borderRadius: DesignRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignRadius.radiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: DesignRadius.radiusMd,
            border: Border.all(
              color:
                  isDark ? DesignColors.borderDark : DesignColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: isDark
                      ? DesignColors.textSecondaryDark
                      : DesignColors.textSecondaryLight),
              const SizedBox(width: 8),
              Text(label,
                  style: DesignTypography.labelMedium(isDark
                      ? DesignColors.textPrimaryDark
                      : DesignColors.textPrimaryLight)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: onPressed != null ? DesignColors.visionGradient : null,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: DesignRadius.radiusMd,
        boxShadow: onPressed != null
            ? DesignColors.shadowColored(DesignColors.vision)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: DesignRadius.radiusMd,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(label,
                          style: DesignTypography.labelLarge(Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: DesignRadius.radiusMd,
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
