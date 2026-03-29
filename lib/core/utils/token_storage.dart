import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over local storage for auth token persistence.
///
/// Uses [SharedPreferences] under the hood. Replace with
/// `flutter_secure_storage` for production-grade security.
class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _accessTokenKey = 'access_token';
  static const _accessExpiresAtKey = 'access_expires_at';
  static const _refreshTokenKey = 'refresh_token';
  static const _refreshExpiresAtKey = 'refresh_expires_at';
  static const _userProfileJsonKey = 'user_profile_json';
  static const _usernameKey = 'auth_username';

  TokenStorage._();

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_accessTokenKey, token);
  }

  static Future<void> saveAuthSession({
    required String accessToken,
    required String accessExpiresAt,
    required String refreshToken,
    required String refreshExpiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_accessExpiresAtKey, accessExpiresAt);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_refreshExpiresAtKey, refreshExpiresAt);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey) ?? prefs.getString(_tokenKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getAccessExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessExpiresAtKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<String?> getRefreshExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshExpiresAtKey);
  }

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  static Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<void> saveUserProfileJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileJsonKey, json);
  }

  static Future<String?> getUserProfileJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userProfileJsonKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_accessExpiresAtKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_refreshExpiresAtKey);
    await prefs.remove(_userProfileJsonKey);
    await prefs.remove(_usernameKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
