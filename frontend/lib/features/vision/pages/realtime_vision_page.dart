import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';

enum _RealtimeVisionMode { scanDechet, ocr, barcode }

class WasteEstimate {
  final String category;
  final double weight;
  final double volume;
  final double conductivity;
  final double opacity;
  final double rigidity;

  WasteEstimate({
    required this.category,
    required this.weight,
    required this.volume,
    required this.conductivity,
    required this.opacity,
    required this.rigidity,
  });
}

class RealtimeVisionPage extends StatefulWidget {
  final String? initialMode;

  const RealtimeVisionPage({super.key, this.initialMode});

  @override
  State<RealtimeVisionPage> createState() => _RealtimeVisionPageState();
}

class _RealtimeVisionPageState extends State<RealtimeVisionPage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  int _lastFrameTimeMs = 0;
  bool _isCapturing = false;

  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  _RealtimeVisionMode _mode = _RealtimeVisionMode.scanDechet;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  String _status = 'Initialisation de la caméra...';
  String _detectedText = '';
  List<String> _barcodes = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      if (widget.initialMode == 'ocr') {
        _mode = _RealtimeVisionMode.ocr;
      } else if (widget.initialMode == 'barcode') {
        _mode = _RealtimeVisionMode.barcode;
      } else {
        _mode = _RealtimeVisionMode.scanDechet;
      }
    }
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopImageStream();
    _cameraController?.dispose();
    _textRecognizer.close();
    _barcodeScanner.close();
    _imageLabeler.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _status = 'Aucune caméra disponible.';
        });
        return;
      }

      _selectedCameraIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      final camera = _availableCameras[_selectedCameraIndex];

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _isCameraReady = true;
        _status = 'Caméra active';
      });

      await _startImageStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Erreur caméra: $e';
      });
    }
  }

  Future<void> _startImageStream() async {
    final controller = _cameraController;
    if (controller == null || controller.value.isStreamingImages) return;

    await controller.startImageStream((image) {
      _processFrame(image);
    });
  }

  Future<void> _stopImageStream() async {
    final controller = _cameraController;
    if (controller == null) return;

    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || _isCapturing) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFrameTimeMs < 250) return; // ~4 analyses/sec
    _lastFrameTimeMs = now;

    final inputImage = _toInputImage(image);
    if (inputImage == null) return;

    _isProcessingFrame = true;

    try {
      switch (_mode) {
        case _RealtimeVisionMode.scanDechet:
          final labels = await _imageLabeler.processImage(inputImage);
          if (!mounted) return;
          setState(() {
            if (labels.isNotEmpty) {
              final top = labels.first;
              _detectedText = '${top.label} (${(top.confidence * 100).toStringAsFixed(0)}%)';
            } else {
              _detectedText = 'Détecteur actif...';
            }
          });
          break;

        case _RealtimeVisionMode.ocr:
          final recognized = await _textRecognizer.processImage(inputImage);
          if (!mounted) return;
          setState(() {
            _detectedText = recognized.text.replaceAll('\n', ' ').trim();
          });
          break;

        case _RealtimeVisionMode.barcode:
          final results = await _barcodeScanner.processImage(inputImage);
          if (!mounted) return;
          setState(() {
            _barcodes = results
                .map((b) => b.displayValue ?? b.rawValue ?? '')
                .where((v) => v.isNotEmpty)
                .toSet()
                .take(3)
                .toList();
          });
          break;
      }
    } catch (e) {
      debugPrint('Erreur analyse flux: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final camera = controller.description;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  void _setMode(_RealtimeVisionMode mode) {
    if (_mode == mode) return;

    setState(() {
      _mode = mode;
      _detectedText = '';
      _barcodes = const [];
    });
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.isEmpty) return;
    HapticFeedback.selectionClick();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    final camera = _availableCameras[_selectedCameraIndex];

    setState(() {
      _isCameraReady = false;
      _status = 'Bascule de la caméra...';
    });

    await _stopImageStream();
    await _cameraController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _isCameraReady = true;
        _status = 'Caméra active';
      });

      if (!_isCapturing) {
        await _startImageStream();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Erreur caméra: $e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    HapticFeedback.selectionClick();

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
      default:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      debugPrint('Erreur flash: $e');
    }
  }

  WasteEstimate _estimateWaste(List<ImageLabel> labels) {
    String bestLabel = '';
    double highestConfidence = 0.0;
    for (final l in labels) {
      if (l.confidence > highestConfidence) {
        highestConfidence = l.confidence;
        bestLabel = l.label;
      }
    }

    final labelLower = bestLabel.toLowerCase();

    if (labelLower.contains('bottle') ||
        labelLower.contains('plastic') ||
        labelLower.contains('pet') ||
        labelLower.contains('cup') ||
        labelLower.contains('packaging') ||
        labelLower.contains('container') ||
        labelLower.contains('trash') ||
        labelLower.contains('waste')) {
      return WasteEstimate(
        category: 'Plastique',
        weight: 0.05,
        volume: 0.5,
        conductivity: 0.1,
        opacity: 0.7,
        rigidity: 4.0,
      );
    } else if (labelLower.contains('can') ||
        labelLower.contains('metal') ||
        labelLower.contains('tin') ||
        labelLower.contains('aluminum') ||
        labelLower.contains('steel') ||
        labelLower.contains('copper') ||
        labelLower.contains('iron')) {
      return WasteEstimate(
        category: 'Métal',
        weight: 0.02,
        volume: 0.33,
        conductivity: 8.5,
        opacity: 1.0,
        rigidity: 7.0,
      );
    } else if (labelLower.contains('paper') ||
        labelLower.contains('cardboard') ||
        labelLower.contains('box') ||
        labelLower.contains('carton') ||
        labelLower.contains('newspaper') ||
        labelLower.contains('magazine') ||
        labelLower.contains('book')) {
      return WasteEstimate(
        category: 'Papier/Carton',
        weight: 0.12,
        volume: 1.0,
        conductivity: 0.0,
        opacity: 1.0,
        rigidity: 2.0,
      );
    } else if (labelLower.contains('glass') ||
        labelLower.contains('jar') ||
        labelLower.contains('glassware') ||
        labelLower.contains('wine') ||
        labelLower.contains('beer')) {
      return WasteEstimate(
        category: 'Verre',
        weight: 0.30,
        volume: 0.75,
        conductivity: 0.0,
        opacity: 0.9,
        rigidity: 9.0,
      );
    }

    return WasteEstimate(
      category: 'Autre',
      weight: 0.15,
      volume: 0.5,
      conductivity: 0.2,
      opacity: 0.6,
      rigidity: 3.5,
    );
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_isCameraReady || _isCapturing) return;

    try {
      HapticFeedback.mediumImpact();
      setState(() {
        _isCapturing = true;
        _status = 'Capture en cours...';
      });

      await _stopImageStream();

      final XFile imageFile = await _cameraController!.takePicture();

      if (!mounted) return;
      _showAnalysisLoadingDialog();

      final inputImage = InputImage.fromFilePath(imageFile.path);

      // Run detectors concurrently
      final labelsFuture = _imageLabeler.processImage(inputImage);
      final ocrFuture = _textRecognizer.processImage(inputImage);
      final barcodeFuture = _barcodeScanner.processImage(inputImage);

      final results = await Future.wait([labelsFuture, ocrFuture, barcodeFuture]);
      
      final labels = results[0] as List<ImageLabel>;
      final recognizedText = results[1] as RecognizedText;
      final barcodes = results[2] as List<Barcode>;

      if (mounted) {
        Navigator.of(context).pop(); // close loader dialog
      }

      final estimate = _estimateWaste(labels);

      String matchedLabelStr = '';
      if (labels.isNotEmpty) {
        final topLabel = labels.first.label;
        final conf = (labels.first.confidence * 100).toStringAsFixed(0);
        matchedLabelStr = '$topLabel ($conf%)';
      }

      String barcodeStr = '';
      if (barcodes.isNotEmpty) {
        barcodeStr = barcodes.first.displayValue ?? barcodes.first.rawValue ?? '';
      }

      final ocrSnippet = recognizedText.text.replaceAll('\n', ' ').trim();
      final shortOcr = ocrSnippet.length > 60 ? '${ocrSnippet.substring(0, 60)}...' : ocrSnippet;

      String prefillRapport = 'Déchet détecté par vision locale';
      if (matchedLabelStr.isNotEmpty) {
        prefillRapport += ' | Objet: $matchedLabelStr';
      }
      if (barcodeStr.isNotEmpty) {
        prefillRapport += ' | Code-barres: $barcodeStr';
      }
      if (shortOcr.isNotEmpty) {
        prefillRapport += ' | Texte: "$shortOcr"';
      }

      if (!mounted) return;
      _showResultBottomSheet(
        imagePath: imageFile.path,
        estimate: estimate,
        matchedLabel: matchedLabelStr,
        barcode: barcodeStr,
        ocrText: shortOcr,
        prefillRapport: prefillRapport,
      );
    } catch (e) {
      debugPrint('Erreur lors de la capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'analyse: $e')),
        );
      }
      setState(() {
        _isCapturing = false;
        _status = 'Caméra active';
      });
      await _startImageStream();
    }
  }

  Future<void> _pickFromGalleryAndAnalyze() async {
    try {
      final picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);
      if (imageFile == null) return;

      HapticFeedback.lightImpact();
      setState(() {
        _isCapturing = true;
      });

      await _stopImageStream();
      _showAnalysisLoadingDialog();

      final inputImage = InputImage.fromFilePath(imageFile.path);

      final labelsFuture = _imageLabeler.processImage(inputImage);
      final ocrFuture = _textRecognizer.processImage(inputImage);
      final barcodeFuture = _barcodeScanner.processImage(inputImage);

      final results = await Future.wait([labelsFuture, ocrFuture, barcodeFuture]);
      
      final labels = results[0] as List<ImageLabel>;
      final recognizedText = results[1] as RecognizedText;
      final barcodes = results[2] as List<Barcode>;

      if (mounted) {
        Navigator.of(context).pop();
      }

      final estimate = _estimateWaste(labels);

      String matchedLabelStr = '';
      if (labels.isNotEmpty) {
        final topLabel = labels.first.label;
        final conf = (labels.first.confidence * 100).toStringAsFixed(0);
        matchedLabelStr = '$topLabel ($conf%)';
      }

      String barcodeStr = '';
      if (barcodes.isNotEmpty) {
        barcodeStr = barcodes.first.displayValue ?? barcodes.first.rawValue ?? '';
      }

      final ocrSnippet = recognizedText.text.replaceAll('\n', ' ').trim();
      final shortOcr = ocrSnippet.length > 60 ? '${ocrSnippet.substring(0, 60)}...' : ocrSnippet;

      String prefillRapport = 'Déchet importé (Galerie)';
      if (matchedLabelStr.isNotEmpty) {
        prefillRapport += ' | Objet: $matchedLabelStr';
      }
      if (barcodeStr.isNotEmpty) {
        prefillRapport += ' | Code-barres: $barcodeStr';
      }
      if (shortOcr.isNotEmpty) {
        prefillRapport += ' | Texte: "$shortOcr"';
      }

      if (!mounted) return;
      _showResultBottomSheet(
        imagePath: imageFile.path,
        estimate: estimate,
        matchedLabel: matchedLabelStr,
        barcode: barcodeStr,
        ocrText: shortOcr,
        prefillRapport: prefillRapport,
      );
    } catch (e) {
      debugPrint('Erreur import galerie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur import: $e')),
        );
      }
      setState(() {
        _isCapturing = false;
      });
      await _startImageStream();
    }
  }

  void _showAnalysisLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? DesignColors.cardDark : DesignColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: DesignRadius.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(DesignColors.ecoSmart),
                ),
                const SizedBox(height: 20),
                Text(
                  'Analyse locale intelligente...',
                  style: TextStyle(
                    color: isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ML Kit identifie le type de déchet, les codes-barres et textes imprimés.',
                  style: TextStyle(
                    color: isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResultBottomSheet({
    required String imagePath,
    required WasteEstimate estimate,
    required String matchedLabel,
    required String barcode,
    required String ocrText,
    required String prefillRapport,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? DesignColors.backgroundDark : DesignColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, -2),
              )
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewPadding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Analyse Locale Réussie',
                  style: TextStyle(
                    color: isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: DesignRadius.radiusMd,
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catégorie estimée',
                            style: TextStyle(
                              color: isDark ? DesignColors.textTertiaryDark : DesignColors.textTertiaryLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            estimate.category,
                            style: TextStyle(
                              color: estimate.category == 'Autre'
                                  ? (isDark ? Colors.white : Colors.black)
                                  : DesignColors.ecoSmart,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (matchedLabel.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Label : $matchedLabel',
                              style: TextStyle(
                                color: isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (barcode.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.qr_code_rounded, size: 14, color: DesignColors.ecoSmart),
                                const SizedBox(width: 4),
                                Text(
                                  'Code-barres : $barcode',
                                  style: TextStyle(
                                    color: isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                
                if (ocrText.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? DesignColors.cardDark : Colors.grey[100],
                      borderRadius: DesignRadius.radiusMd,
                      border: Border.all(
                        color: isDark ? DesignColors.borderDark : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Texte détecté (OCR) :',
                          style: TextStyle(
                            color: isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"$ocrText"',
                          style: TextStyle(
                            color: isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                Text(
                  'Caractéristiques physiques estimées :',
                  style: TextStyle(
                    color: isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ConstantChip(
                      icon: Icons.scale_rounded,
                      label: 'Poids',
                      value: '${estimate.weight} kg',
                      isDark: isDark,
                    ),
                    _ConstantChip(
                      icon: Icons.opacity_rounded,
                      label: 'Opacité',
                      value: '${(estimate.opacity * 10).toStringAsFixed(0)}/10',
                      isDark: isDark,
                    ),
                    _ConstantChip(
                      icon: Icons.flash_on_rounded,
                      label: 'Conductivité',
                      value: '${estimate.conductivity} S/m',
                      isDark: isDark,
                    ),
                    _ConstantChip(
                      icon: Icons.fitness_center_rounded,
                      label: 'Rigidité',
                      value: '${(estimate.rigidity).toStringAsFixed(0)}/10',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignColors.ecoSmart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: DesignRadius.radiusMd),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    
                    final uri = Uri(
                      path: '/eco-smart',
                      queryParameters: {
                        'prefillRapport': prefillRapport,
                        'prefillPoids': estimate.weight.toString(),
                        'prefillVolume': estimate.volume.toString(),
                        'prefillConductivite': estimate.conductivity.toString(),
                        'prefillOpacite': estimate.opacity.toString(),
                        'prefillRigidite': estimate.rigidity.toString(),
                      },
                    );
                    context.go(uri.toString());
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Exporter vers Eco-Smart',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: DesignRadius.radiusMd),
                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    
                    setState(() {
                      _isCapturing = false;
                      _status = 'Caméra active';
                    });
                    await _startImageStream();
                  },
                  child: Text(
                    'Reprendre la photo',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (_isCapturing) {
        setState(() {
          _isCapturing = false;
          _status = 'Caméra active';
        });
        _startImageStream();
      }
    });
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: DesignColors.ecoSmart),
              const SizedBox(height: 16),
              Text(
                _status,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    double cameraRatio = _cameraController!.value.aspectRatio;
    if (cameraRatio > 1) {
      cameraRatio = 1 / cameraRatio;
    }

    double scale = 1.0;
    if (deviceRatio < cameraRatio) {
      scale = cameraRatio / deviceRatio;
    } else {
      scale = deviceRatio / cameraRatio;
    }

    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildTopBar() {
    IconData flashIcon = Icons.flash_off_rounded;
    if (_flashMode == FlashMode.torch) flashIcon = Icons.flash_on_rounded;
    if (_flashMode == FlashMode.auto) flashIcon = Icons.flash_auto_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _mode == _RealtimeVisionMode.scanDechet
                ? 'Scan Déchet'
                : _mode == _RealtimeVisionMode.ocr
                    ? 'Texte (OCR)'
                    : 'Code-barres',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        GestureDetector(
          onTap: _toggleFlash,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(flashIcon, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final showResultText = _detectedText.isNotEmpty || _barcodes.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showResultText && !_isCapturing) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesignColors.ecoSmart.withValues(alpha: 0.4)),
              ),
              child: Text(
                _mode == _RealtimeVisionMode.barcode
                    ? (_barcodes.isNotEmpty ? 'Code-barres: ${_barcodes.first}' : 'Prêt à scanner')
                    : _detectedText,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton(_RealtimeVisionMode.scanDechet, 'Scan Déchet', Icons.eco_rounded),
                  _buildModeButton(_RealtimeVisionMode.ocr, 'Texte', Icons.text_fields_rounded),
                  _buildModeButton(_RealtimeVisionMode.barcode, 'Code-barres', Icons.qr_code_scanner_rounded),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _toggleCamera,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  GestureDetector(
                    onTap: _captureAndAnalyze,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickFromGalleryAndAnalyze,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(_RealtimeVisionMode mode, String label, IconData icon) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => _setMode(mode),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? DesignColors.ecoSmart : Colors.white60,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? DesignColors.ecoSmart : Colors.white60,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildCameraPreview(),
          ),
          if (_isCameraReady)
            const Positioned.fill(
              child: _ViewfinderOverlay(),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: DesignColors.ecoSmart.withValues(alpha: 0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Container(width: 20, height: 2, color: DesignColors.ecoSmart),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(width: 2, height: 20, color: DesignColors.ecoSmart),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(width: 20, height: 2, color: DesignColors.ecoSmart),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(width: 2, height: 20, color: DesignColors.ecoSmart),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(width: 20, height: 2, color: DesignColors.ecoSmart),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(width: 2, height: 20, color: DesignColors.ecoSmart),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(width: 20, height: 2, color: DesignColors.ecoSmart),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(width: 2, height: 20, color: DesignColors.ecoSmart),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstantChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ConstantChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.cardDark : Colors.grey[100],
        borderRadius: DesignRadius.radiusMd,
        border: Border.all(
          color: isDark ? DesignColors.borderDark : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DesignColors.ecoSmart),
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: TextStyle(
              color: isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
