import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/utils/device_context.dart';
import 'package:flutter_synergy/features/attendance/attendance_models.dart';

String _fileName(String filePath) {
  final norm = filePath.replaceAll(r'\', '/');
  final i = norm.lastIndexOf('/');
  return i < 0 ? norm : norm.substring(i + 1);
}

/// Multipart check-in / check-out per `api_mobile` form-data contract.
class AttendanceService {
  AttendanceService(this._api);

  final ApiClient _api;

  /// `DateTime` in local timezone, formatted like `2026-03-21T07:30:00+07:00`.
  static String formatCheckTimestamp(DateTime local) {
    final t = local.toLocal();
    final offset = t.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final oh = offset.inHours.abs().toString().padLeft(2, '0');
    final om =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}'
        'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}'
        '$sign$oh:$om';
  }

  Future<void> submitAttendance({
    required AttendanceSubmitKind kind,
    required String attachmentPath,
    required double lat,
    required double lon,
    DateTime? at,
  }) async {
    final timestamp = at ?? DateTime.now();
    final deviceId = await DeviceContext.getOrCreateDeviceId();
    final ip = await DeviceContext.bestEffortLocalIpv4();

    final file = File(attachmentPath);
    if (!await file.exists()) {
      throw const ApiException(message: 'Photo file not found.');
    }

    final form = FormData.fromMap({
      'remark': kind.remark,
      'lat': lat.toString(),
      'lon': lon.toString(),
      kind.timeFieldName: formatCheckTimestamp(timestamp),
      'device_info[device_id]': deviceId,
      // API spelling (single "s"): matches Postman / backend.
      'device_info[ip_addres]': ip.isEmpty ? '0.0.0.0' : ip,
      'attachment': await MultipartFile.fromFile(
        attachmentPath,
        filename: _fileName(attachmentPath),
      ),
    });

    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        kind.path,
        data: form,
      );
      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw ApiException(
          message:
              (body['message'] ?? 'Attendance submission failed').toString(),
          statusCode: response.statusCode,
          data: body,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
