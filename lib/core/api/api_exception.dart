import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/api/api_request_extra.dart';

/// Unified exception wrapper for API errors.
///
/// Translates [DioException] into user-friendly messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final bool sessionExpired;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.sessionExpired = false,
  });

  factory ApiException.fromDioException(DioException error) {
    final sessionExpired =
        error.requestOptions.extra[ApiRequestExtra.sessionExpired] == true;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please try again.',
          sessionExpired: sessionExpired,
        );
      case DioExceptionType.badResponse:
        final responseData = error.response?.data;
        return ApiException(
          message:
              _messageFromResponseData(responseData) ??
              _messageFromStatusCode(error.response?.statusCode),
          statusCode: error.response?.statusCode,
          data: responseData,
          sessionExpired: sessionExpired,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          sessionExpired: sessionExpired,
        );
      default:
        return ApiException(
          message: 'Unable to connect. Check your internet connection.',
          sessionExpired: sessionExpired,
        );
    }
  }

  static String? _messageFromResponseData(dynamic data) {
    if (data is Map) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      final error = data['error']?.toString().trim();
      if (error != null && error.isNotEmpty) {
        return error;
      }
    }
    return null;
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
