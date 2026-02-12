import 'package:dio/dio.dart';

/// Unified exception wrapper for API errors.
///
/// Translates [DioException] into user-friendly messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please try again.',
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: _messageFromStatusCode(error.response?.statusCode),
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      default:
        return const ApiException(
          message: 'Unable to connect. Check your internet connection.',
        );
    }
  }

  static String _messageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request.';
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Internal server error. Please try again later.';
      default:
        return 'Something went wrong (code: $statusCode).';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
