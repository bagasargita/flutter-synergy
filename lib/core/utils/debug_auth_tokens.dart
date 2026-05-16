import 'package:flutter/foundation.dart';
import 'package:flutter_synergy/core/utils/token_storage.dart';

/// Debug-only helpers to overwrite stored tokens for auth / refresh testing.
///
/// Only callable in debug builds ([kDebugMode]).
abstract final class DebugAuthTokens {
  DebugAuthTokens._();

  static const invalidAccessToken = 'debug-invalid-access-token';
  static const invalidRefreshToken = 'debug-invalid-refresh-token';
  static const dummyExpiresAt = '2099-12-31T00:00:00Z';

  /// Invalid access + invalid refresh → API 401, refresh fails, session expires.
  static Future<void> applyInvalidAccessAndRefresh() async {
    assert(kDebugMode, 'DebugAuthTokens is only for debug builds');
    await TokenStorage.saveAuthSession(
      accessToken: invalidAccessToken,
      accessExpiresAt: dummyExpiresAt,
      refreshToken: invalidRefreshToken,
      refreshExpiresAt: dummyExpiresAt,
    );
  }

  /// Invalid access only; keeps the current refresh token from the last login.
  static Future<void> applyInvalidAccessOnly() async {
    assert(kDebugMode, 'DebugAuthTokens is only for debug builds');
    final refreshToken =
        await TokenStorage.getRefreshToken() ?? invalidRefreshToken;
    final refreshExpiresAt =
        await TokenStorage.getRefreshExpiresAt() ?? dummyExpiresAt;

    await TokenStorage.saveAuthSession(
      accessToken: invalidAccessToken,
      accessExpiresAt: dummyExpiresAt,
      refreshToken: refreshToken,
      refreshExpiresAt: refreshExpiresAt,
    );
  }
}
