import 'package:flutter_synergy/features/attendance/attendance_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceSubmitKindApi', () {
    test('checkIn maps to expected API contract', () {
      expect(AttendanceSubmitKind.checkIn.remark, 'checkin');
      expect(AttendanceSubmitKind.checkIn.timeFieldName, 'check_in_at');
      expect(AttendanceSubmitKind.checkIn.path, '/attendances/check_in');
    });

    test('checkOut maps to expected API contract', () {
      expect(AttendanceSubmitKind.checkOut.remark, 'checkout');
      expect(AttendanceSubmitKind.checkOut.timeFieldName, 'check_out_at');
      expect(AttendanceSubmitKind.checkOut.path, '/attendances/check_out');
    });
  });
}
