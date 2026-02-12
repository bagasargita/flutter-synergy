import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over local storage for auth token persistence.
///
/// Uses [SharedPreferences] under the hood. Replace with
/// `flutter_secure_storage` for production-grade security.
class TokenStorage {
  static const _tokenKey = 'auth_token';

  TokenStorage._();

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
