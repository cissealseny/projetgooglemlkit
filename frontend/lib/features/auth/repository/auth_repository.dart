import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<User> login(String email, String password) async {
    final response = await _apiClient.login({
      'email': email,
      'password': password,
    });

    final data = response.data;

    // Save tokens
    await _storage.write(key: 'access_token', value: data['tokens']['access']);
    await _storage.write(
      key: 'refresh_token',
      value: data['tokens']['refresh'],
    );

    return User.fromJson(data['user']);
  }

  Future<User> register({
    required String email,
    required String username,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    final response = await _apiClient.register({
      'email': email,
      'username': username,
      'password': password,
      'password_confirm': password,
      'first_name': firstName,
      'last_name': lastName,
    });

    final data = response.data;

    // Save tokens
    await _storage.write(key: 'access_token', value: data['tokens']['access']);
    await _storage.write(
      key: 'refresh_token',
      value: data['tokens']['refresh'],
    );

    return User.fromJson(data['user']);
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        await _apiClient.logout(refreshToken);
      } catch (_) {}
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<User> getProfile() async {
    final response = await _apiClient.getProfile();
    return User.fromJson(response.data);
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.updateProfile(data);
    return User.fromJson(response.data);
  }
}
