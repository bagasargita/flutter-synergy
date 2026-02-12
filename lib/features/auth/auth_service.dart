import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:dio/dio.dart';

/// Data model returned by the login endpoint.
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String token;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
    );
  }
}

/// Handles authentication-related API calls.
class AuthService {
  // ignore: unused_field
  final ApiClient _api; // Will be used with real API endpoints.

  AuthService(this._api);

  /// Performs login. In dev mode this returns mock data after a
  /// short delay to simulate network latency.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      // --- Mock implementation (replace with real endpoint) ---
      await Future<void>.delayed(const Duration(seconds: 2));

      // Simulate validation
      if (email.isEmpty || password.isEmpty) {
        throw const ApiException(message: 'Email and password are required.');
      }

      if (password.length < 6) {
        throw const ApiException(message: 'Invalid credentials.');
      }

      // Return mock user
      return AuthUser(
        id: 'usr_001',
        name: 'John Doe',
        email: email,
        token: 'mock_jwt_token_abc123',
      );

      // --- Real implementation (uncomment when backend is ready) ---
      // final response = await _api.post('/auth/login', data: {
      //   'email': email,
      //   'password': password,
      // });
      // return AuthUser.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    AppLogger.info('User logged out');
    // await _api.post('/auth/logout');
  }
}
