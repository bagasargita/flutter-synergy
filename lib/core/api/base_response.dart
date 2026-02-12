/// Generic wrapper for API responses.
///
/// Standardizes the shape returned by the backend so every feature
/// can rely on a common contract: `success`, `message`, and `data`.
class BaseResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const BaseResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return BaseResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}
