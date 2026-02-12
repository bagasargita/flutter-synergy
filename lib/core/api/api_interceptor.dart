import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/core/utils/token_storage.dart';

/// Interceptor that attaches the auth token to every outgoing request.
class AuthInterceptor extends Interceptor {
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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      AppLogger.warning('Unauthorized – token may be expired');
      // TODO: trigger token refresh or logout flow
    }
    handler.next(err);
  }
}

/// Interceptor that logs request/response details for debugging.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info(
      '→ ${options.method} ${options.uri}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      '← ${response.statusCode} ${response.requestOptions.uri}',
    );
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
