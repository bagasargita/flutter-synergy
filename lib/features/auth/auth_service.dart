import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:dio/dio.dart';

/// Data model returned by the login endpoint.
class AuthUser {
  final String id;
  final String name;
  final String username;
  final String accessToken;
  final String accessExpiresAt;
  final String refreshToken;
  final String refreshExpiresAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? '').toString(),
      accessExpiresAt: (json['accessExpiresAt'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      refreshExpiresAt: (json['refreshExpiresAt'] ?? '').toString(),
    );
  }
}

/// Handles authentication-related API calls.
class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  /// Performs login against the backend `sign_in` endpoint.
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        throw const ApiException(message: 'Email and password are required.');
      }

      final response = await _api.post<Map<String, dynamic>>(
        '/sign_in',
        data: {
          'username': username,
          'password': password,
        },
      );

      final body = response.data ?? <String, dynamic>{};
      final success = body['success'] == true;

      if (!success) {
        throw ApiException(
          message: (body['message'] ?? 'Login failed').toString(),
          statusCode: response.statusCode,
        );
      }

      final data = body['data'] as Map<String, dynamic>?;
      final access = data?['access'] as Map<String, dynamic>?;
      final refresh = data?['refresh'] as Map<String, dynamic>?;
      final accessToken = (access?['token'] ?? '').toString();
      final accessExpiresAt = (access?['expires_at'] ?? '').toString();
      final refreshToken = (refresh?['token'] ?? '').toString();
      final refreshExpiresAt = (refresh?['expires_at'] ?? '').toString();

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw const ApiException(message: 'Token data missing in response.');
      }

      return AuthUser(
        id: (data?['id'] ?? '').toString(),
        name: (data?['name'] ?? '').toString(),
        username: username,
        accessToken: accessToken,
        accessExpiresAt: accessExpiresAt,
        refreshToken: refreshToken,
        refreshExpiresAt: refreshExpiresAt,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    AppLogger.info('User logged out');
    // await _api.post('/auth/logout');
  }
}
