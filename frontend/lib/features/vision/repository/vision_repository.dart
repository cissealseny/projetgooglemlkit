import 'dart:io';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../services/mlkit_vision_service.dart';

class VisionRepository {
  final ApiClient _apiClient;
  final MLKitVisionService _mlkitService;

  VisionRepository(this._apiClient, this._mlkitService);

  /// Perform OCR using ML Kit (on-device)
  Future<Map<String, dynamic>> performLocalOCR(String imagePath) async {
    return await _mlkitService.performOCR(imagePath);
  }

  /// Perform OCR using backend API
  Future<Map<String, dynamic>> performRemoteOCR(
    File imageFile, {
    String language = 'fr',
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      'language': language,
    });

    final response = await _apiClient.performOCR(formData);
    return response.data;
  }

  /// Detect faces using ML Kit (on-device)
  Future<Map<String, dynamic>> detectFacesLocal(String imagePath) async {
    return await _mlkitService.detectFaces(imagePath);
  }

  /// Detect faces using backend API
  Future<Map<String, dynamic>> detectFacesRemote(
    File imageFile, {
    bool includeEmotions = true,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      'include_emotions': includeEmotions,
    });

    final response = await _apiClient.detectFaces(formData);
    return response.data;
  }

  /// Detect objects using ML Kit (on-device)
  Future<Map<String, dynamic>> detectObjectsLocal(String imagePath) async {
    return await _mlkitService.detectObjects(imagePath);
  }

  /// Detect objects using backend API
  Future<Map<String, dynamic>> detectObjectsRemote(
    File imageFile, {
    int maxResults = 10,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      'max_results': maxResults,
    });

    final response = await _apiClient.detectObjects(formData);
    return response.data;
  }

  /// Label image using ML Kit (on-device)
  Future<Map<String, dynamic>> labelImageLocal(String imagePath) async {
    return await _mlkitService.labelImage(imagePath);
  }

  /// Label image using backend API
  Future<Map<String, dynamic>> labelImageRemote(
    File imageFile, {
    int maxLabels = 10,
    double minConfidence = 0.5,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      'max_labels': maxLabels,
      'min_confidence': minConfidence,
    });

    final response = await _apiClient.labelImage(formData);
    return response.data;
  }

  /// Scan barcodes using ML Kit (on-device only)
  Future<Map<String, dynamic>> scanBarcodes(String imagePath) async {
    return await _mlkitService.scanBarcodes(imagePath);
  }

  /// Get vision analysis history from backend
  Future<List<dynamic>> getHistory() async {
    final response = await _apiClient.getVisionHistory();
    // Handle Django paginated response
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List<dynamic>;
    }
    return [];
  }
}
