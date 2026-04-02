import 'package:flutter_synergy/features/attendance/attendance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceService.formatCheckTimestamp', () {
    test('formats local timestamp with timezone offset', () {
      final date = DateTime(2026, 4, 3, 9, 5, 7);

      final out = AttendanceService.formatCheckTimestamp(date);

      expect(
        out,
        matches(
          RegExp(
            r'^2026-04-03T09:05:07[+-]\d{2}:\d{2}$',
          ),
        ),
      );
    });
  });
}
