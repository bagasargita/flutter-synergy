import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/api/api_interceptor.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/core/utils/environment.dart';

/// Centralized API client built on top of Dio.
///
/// Provides a single configured [Dio] instance for the entire app
/// with interceptors for auth, logging, and error handling.
class ApiClient {
  late final Dio _dio;

  ApiClient({required Environment environment}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: environment.baseUrl,
        connectTimeout: const Duration(seconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_dio),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
