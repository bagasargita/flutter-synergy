import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException.fromDioException', () {
    test('maps timeout errors to timeout message', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );

      final mapped = ApiException.fromDioException(ex);

      expect(mapped.message, 'Connection timed out. Please try again.');
    });

    test('uses API message from badResponse payload', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 401,
          data: <String, dynamic>{'message': 'Invalid credentials'},
        ),
        type: DioExceptionType.badResponse,
      );

      final mapped = ApiException.fromDioException(ex);

      expect(mapped.statusCode, 401);
      expect(mapped.message, 'Invalid credentials');
    });

    test('falls back to status-based message when payload has no message', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/secure'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/secure'),
          statusCode: 403,
          data: <String, dynamic>{'details': 'forbidden'},
        ),
        type: DioExceptionType.badResponse,
      );

      final mapped = ApiException.fromDioException(ex);

      expect(mapped.message, 'Access denied.');
    });

    test('maps cancel to cancelled message', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.cancel,
      );

      final mapped = ApiException.fromDioException(ex);
      expect(mapped.message, 'Request was cancelled.');
    });

    test('maps unknown errors to connectivity message', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.unknown,
      );

      final mapped = ApiException.fromDioException(ex);
      expect(mapped.message, 'Unable to connect. Check your internet connection.');
    });
  });
}
