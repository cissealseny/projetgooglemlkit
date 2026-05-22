import '../../../core/network/api_client.dart';

class EcoSmartRepository {
  final ApiClient _apiClient;

  EcoSmartRepository(this._apiClient);

  Future<Map<String, dynamic>> classify(Map<String, dynamic> payload) async {
    final response = await _apiClient.ecoClassify(payload);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> estimate(Map<String, dynamic> payload) async {
    final response = await _apiClient.ecoEstimate(payload);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cluster(Map<String, dynamic> payload) async {
    final response = await _apiClient.ecoCluster(payload);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> nlp(Map<String, dynamic> payload) async {
    final response = await _apiClient.ecoNlp(payload);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> multimodal(Map<String, dynamic> payload) async {
    final response = await _apiClient.ecoMultimodal(payload);
    return response.data as Map<String, dynamic>;
  }
}
