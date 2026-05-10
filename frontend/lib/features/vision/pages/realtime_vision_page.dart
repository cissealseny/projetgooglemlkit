import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum _RealtimeVisionMode { ocr, face, barcode }

class RealtimeVisionPage extends StatefulWidget {
  const RealtimeVisionPage({super.key});

  @override
  State<RealtimeVisionPage> createState() => _RealtimeVisionPageState();
}

class _RealtimeVisionPageState extends State<RealtimeVisionPage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  int _lastFrameTimeMs = 0;
  int _processedFrames = 0;

  _RealtimeVisionMode _mode = _RealtimeVisionMode.ocr;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: true,
    ),
  );
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  String _status = 'Initialisation de la caméra...';
  String _detectedText = '';
  int _faceCount = 0;
  List<String> _barcodes = const [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopImageStream();
    _cameraController?.dispose();
    _textRecognizer.close();
    _faceDetector.close();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _status = 'Aucune caméra disponible.';
        });
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

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
        _status = 'Caméra active - analyse en temps réel';
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
    if (_isProcessingFrame) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFrameTimeMs < 220) return; // ~4-5 analyses/sec
    _lastFrameTimeMs = now;

    final inputImage = _toInputImage(image);
    if (inputImage == null) return;

    _isProcessingFrame = true;

    try {
      switch (_mode) {
        case _RealtimeVisionMode.ocr:
          final recognized = await _textRecognizer.processImage(inputImage);
          if (!mounted) return;
          setState(() {
            _processedFrames += 1;
            _detectedText = recognized.text;
          });
          break;

        case _RealtimeVisionMode.face:
          final faces = await _faceDetector.processImage(inputImage);
          if (!mounted) return;
          setState(() {
            _processedFrames += 1;
            _faceCount = faces.length;
          });
          break;

        case _RealtimeVisionMode.barcode:
          final results = await _barcodeScanner.processImage(inputImage);
          if (!mounted) return;
          setState(() {
            _processedFrames += 1;
            _barcodes = results
                .map((b) => b.displayValue ?? b.rawValue ?? '')
                .where((v) => v.isNotEmpty)
                .toSet()
                .take(6)
                .toList();
          });
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Erreur analyse: $e';
      });
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
      _faceCount = 0;
      _barcodes = const [];
      _processedFrames = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vision temps réel')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: _buildCameraPreview(),
          ),
          Expanded(
            flex: 4,
            child: _buildControlPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null) {
      return Center(
        child: Text(
          _status,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      child: Center(
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mode d\'analyse',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('OCR'),
                selected: _mode == _RealtimeVisionMode.ocr,
                onSelected: (_) => _setMode(_RealtimeVisionMode.ocr),
              ),
              ChoiceChip(
                label: const Text('Visages'),
                selected: _mode == _RealtimeVisionMode.face,
                onSelected: (_) => _setMode(_RealtimeVisionMode.face),
              ),
              ChoiceChip(
                label: const Text('Codes-barres'),
                selected: _mode == _RealtimeVisionMode.barcode,
                onSelected: (_) => _setMode(_RealtimeVisionMode.barcode),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Frames analysées: $_processedFrames',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    switch (_mode) {
      case _RealtimeVisionMode.ocr:
        return _ResultCard(
          title: 'Texte détecté',
          content: _detectedText.trim().isEmpty
              ? 'Aucun texte détecté pour le moment.'
              : _detectedText.trim(),
        );

      case _RealtimeVisionMode.face:
        return _ResultCard(
          title: 'Visages détectés',
          content: '$_faceCount visage(s)',
        );

      case _RealtimeVisionMode.barcode:
        return _ResultCard(
          title: 'Codes-barres détectés',
          content: _barcodes.isEmpty
              ? 'Aucun code-barres détecté pour le moment.'
              : _barcodes.join('\n'),
        );
    }
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String content;

  const _ResultCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SelectableText(content),
          ],
        ),
      ),
    );
  }
}
