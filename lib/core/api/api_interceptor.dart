import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/core/utils/token_storage.dart';

/// Interceptor that attaches the auth token to every outgoing request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  Future<String?>? _refreshFuture;
  static const _retryKey = 'auth_retry';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshRequest =
        request.path == '/refresh' || request.uri.path.endsWith('/refresh');
    final alreadyRetried = request.extra[_retryKey] == true;

    if (!isUnauthorized || isRefreshRequest || alreadyRetried) {
      handler.next(err);
      return;
    }

    AppLogger.warning('Unauthorized - attempting token refresh');

    final refreshedAccessToken = await _refreshAccessToken(
      baseUrl: request.baseUrl,
    );

    if (refreshedAccessToken == null || refreshedAccessToken.isEmpty) {
      AppLogger.warning('Refresh token failed - clearing local session');
      await TokenStorage.clearToken();
      handler.next(err);
      return;
    }

    request.headers['Authorization'] = 'Bearer $refreshedAccessToken';
    request.extra[_retryKey] = true;

    try {
      final retryResponse = await _dio.fetch<dynamic>(request);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken({required String baseUrl}) async {
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;

    _refreshFuture = _doRefresh(baseUrl: baseUrl);

    try {
      return await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _doRefresh({required String baseUrl}) async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/refresh',
        data: {'refresh_token': refreshToken},
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) return null;

      final data = body['data'] as Map<String, dynamic>?;
      final access = data?['access'] as Map<String, dynamic>?;
      final refresh = data?['refresh'] as Map<String, dynamic>?;

      final nextAccessToken = (access?['token'] ?? '').toString();
      if (nextAccessToken.isEmpty) return null;

      final nextAccessExpiresAt = (access?['expires_at'] ?? '').toString();
      final nextRefreshToken = (refresh?['token'] ?? refreshToken).toString();
      final nextRefreshExpiresAt =
          (refresh?['expires_at'] ??
                  await TokenStorage.getRefreshExpiresAt() ??
                  '')
              .toString();

      await TokenStorage.saveAuthSession(
        accessToken: nextAccessToken,
        accessExpiresAt: nextAccessExpiresAt,
        refreshToken: nextRefreshToken,
        refreshExpiresAt: nextRefreshExpiresAt,
      );

      return nextAccessToken;
    } on DioException {
      return null;
    }
  }
}

/// Interceptor that logs request/response details for debugging.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '✖ ${err.response?.statusCode ?? 'NO_STATUS'} ${err.requestOptions.uri}',
      error: err,
    );
    handler.next(err);
  }
}
