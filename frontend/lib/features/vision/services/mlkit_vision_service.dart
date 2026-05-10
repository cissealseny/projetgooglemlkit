import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class MLKitVisionService {
  // Text Recognition
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Face Detection
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
    ),
  );

  // Object Detection
  ObjectDetector? _objectDetector;

  // Image Labeling
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  // Barcode Scanner
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  /// Perform OCR on an image file
  Future<Map<String, dynamic>> performOCR(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      stopwatch.stop();

      final blocks = recognizedText.blocks.map((block) {
        return {
          'text': block.text,
          'confidence': block.recognizedLanguages.isNotEmpty
              ? block.recognizedLanguages.first
              : null,
          'boundingBox': {
            'left': block.boundingBox.left,
            'top': block.boundingBox.top,
            'right': block.boundingBox.right,
            'bottom': block.boundingBox.bottom,
          },
          'lines': block.lines.map((line) => line.text).toList(),
        };
      }).toList();

      return {
        'success': true,
        'text': recognizedText.text,
        'blocks': blocks,
        'blockCount': recognizedText.blocks.length,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Detect faces in an image
  Future<Map<String, dynamic>> detectFaces(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      stopwatch.stop();

      final faceData = faces.map((face) {
        return {
          'boundingBox': {
            'left': face.boundingBox.left,
            'top': face.boundingBox.top,
            'right': face.boundingBox.right,
            'bottom': face.boundingBox.bottom,
          },
          'headEulerAngleX': face.headEulerAngleX,
          'headEulerAngleY': face.headEulerAngleY,
          'headEulerAngleZ': face.headEulerAngleZ,
          'smilingProbability': face.smilingProbability,
          'leftEyeOpenProbability': face.leftEyeOpenProbability,
          'rightEyeOpenProbability': face.rightEyeOpenProbability,
          'trackingId': face.trackingId,
        };
      }).toList();

      return {
        'success': true,
        'faces': faceData,
        'count': faces.length,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Detect objects in an image
  Future<Map<String, dynamic>> detectObjects(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Initialize object detector if needed
      _objectDetector ??= ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );

      final inputImage = InputImage.fromFilePath(imagePath);
      final objects = await _objectDetector!.processImage(inputImage);

      stopwatch.stop();

      final objectData = objects.map((obj) {
        return {
          'boundingBox': {
            'left': obj.boundingBox.left,
            'top': obj.boundingBox.top,
            'right': obj.boundingBox.right,
            'bottom': obj.boundingBox.bottom,
          },
          'labels': obj.labels
              .map(
                (label) => {
                  'text': label.text,
                  'confidence': label.confidence,
                  'index': label.index,
                },
              )
              .toList(),
          'trackingId': obj.trackingId,
        };
      }).toList();

      return {
        'success': true,
        'objects': objectData,
        'count': objects.length,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Label an image
  Future<Map<String, dynamic>> labelImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      stopwatch.stop();

      final labelData = labels.map((label) {
        return {
          'text': label.label,
          'confidence': label.confidence,
          'index': label.index,
        };
      }).toList();

      return {
        'success': true,
        'labels': labelData,
        'count': labels.length,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Scan barcodes in an image
  Future<Map<String, dynamic>> scanBarcodes(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      stopwatch.stop();

      final barcodeData = barcodes.map((barcode) {
        return {
          'rawValue': barcode.rawValue,
          'displayValue': barcode.displayValue,
          'format': barcode.format.name,
          'type': barcode.type.name,
          'boundingBox': {
            'left': barcode.boundingBox.left,
            'top': barcode.boundingBox.top,
            'right': barcode.boundingBox.right,
            'bottom': barcode.boundingBox.bottom,
          },
        };
      }).toList();

      return {
        'success': true,
        'barcodes': barcodeData,
        'count': barcodes.length,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Dispose all detectors
  void dispose() {
    _textRecognizer.close();
    _faceDetector.close();
    _objectDetector?.close();
    _imageLabeler.close();
    _barcodeScanner.close();
  }
}
