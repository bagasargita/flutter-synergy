import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/security/security_report.dart';
import 'package:flutter_synergy/core/security/security_service.dart';
import 'package:flutter_synergy/core/utils/device_context.dart';
import 'package:flutter_synergy/core/utils/form_data_logger.dart';
import 'package:flutter_synergy/features/attendance/attendance_models.dart';

String _fileName(String filePath) {
  final norm = filePath.replaceAll(r'\', '/');
  final i = norm.lastIndexOf('/');
  return i < 0 ? norm : norm.substring(i + 1);
}

/// Encodes camera JPEG to WebP for API `attachment` (matches Postman `sample1.webp`).
Future<File> _jpegToWebpTemp(String jpegPath) async {
  final dir = await getTemporaryDirectory();
  final outPath =
      '${dir.path}/face_capture_${DateTime.now().millisecondsSinceEpoch}.webp';
  final result = await FlutterImageCompress.compressAndGetFile(
    jpegPath,
    outPath,
    format: CompressFormat.webp,
    quality: 85,
  );
  if (result == null) {
    throw const ApiException(message: 'Could not encode photo as WebP.');
  }
  return File(result.path);
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
    final om = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}'
        'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}'
        '$sign$oh:$om';
  }

  /// [attachmentPath] is required when the user must submit a selfie; omit or pass
  /// `null` when `selfie_required` is false on `/users/me`.
  ///
  /// Runs [SecurityService.checkSecurity] immediately before upload. If the location
  /// is not trusted, throws [ApiException] with a specific [attendanceSecurityBlockMessage]
  /// and [kAttendanceSecurityBlockDataKey] in [ApiException.data].
  Future<void> submitAttendance({
    required AttendanceSubmitKind kind,
    String? attachmentPath,
    DateTime? at,
  }) async {
    final report = await SecurityService.instance.checkSecurity();
    if (report.isRisky) {
      throw ApiException(
        message: attendanceSecurityBlockMessage(report),
        data: <String, dynamic>{kAttendanceSecurityBlockDataKey: true},
      );
    }
    final locationSnapshot = SecurityService.instance.lastAcceptedSnapshot;
    if (locationSnapshot == null) {
      throw ApiException(
        message: attendanceSecurityBlockMessage(report),
        data: <String, dynamic>{kAttendanceSecurityBlockDataKey: true},
      );
    }

    final lat = locationSnapshot.latitude;
    final lon = locationSnapshot.longitude;

    final timestamp = at ?? DateTime.now();
    final deviceId = await DeviceContext.getOrCreateDeviceId();
    final ip = await DeviceContext.bestEffortLocalIpv4();

    final path = attachmentPath?.trim() ?? '';
    final hasPhoto = path.isNotEmpty;

    File? webpFile;
    try {
      final fields = <String, dynamic>{
        'remark': kind.remark,
        'lat': lat.toString(),
        'lon': lon.toString(),
        kind.timeFieldName: formatCheckTimestamp(timestamp),
        'device_info[device_id]': deviceId,
        // API spelling (single "s"): matches Postman / backend.
        'device_info[ip_addres]': ip.isEmpty ? '0.0.0.0' : ip,
      };

      if (hasPhoto) {
        final file = File(path);
        if (!await file.exists()) {
          throw const ApiException(message: 'Photo file not found.');
        }
        webpFile = await _jpegToWebpTemp(path);
        final webpName = _fileName(webpFile.path);
        fields['attachment'] = await MultipartFile.fromFile(
          webpFile.path,
          filename: webpName,
          contentType: MediaType('image', 'webp'),
        );
      }

      final form = FormData.fromMap(fields);

      logFormData(form, label: 'POST ${kind.path}');

      final response = await _api.dio.post<Map<String, dynamic>>(
        kind.path,
        data: form,
      );
      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw ApiException(
          message: (body['message'] ?? 'Attendance submission failed')
              .toString(),
          statusCode: response.statusCode,
          data: body,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } finally {
      try {
        if (webpFile != null && await webpFile.exists()) {
          await webpFile.delete();
        }
      } catch (_) {}
    }
  }
}
