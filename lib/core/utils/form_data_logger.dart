import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/utils/logger.dart';

/// Logs multipart form-data payloads in a readable format.
///
/// Reusable across features when debugging API requests.
void logFormData(FormData form, {required String label}) {
  final lines = <String>['$label FormData:'];
  for (final e in form.fields) {
    lines.add('  ${e.key}: ${e.value}');
  }
  for (final e in form.files) {
    final f = e.value;
    final contentType = f.contentType?.toString() ?? 'unknown';
    lines.add(
      '  ${e.key}: file(${f.filename ?? "?"}, ${f.length}B, $contentType)',
    );
  }
  AppLogger.info(lines.join('\n'));
}
