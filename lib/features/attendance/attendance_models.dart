/// Whether the user is submitting [checkIn] or [checkOut] attendance.
enum AttendanceSubmitKind { checkIn, checkOut }

extension AttendanceSubmitKindApi on AttendanceSubmitKind {
  /// API expects `checkin` / `checkout` for [remark] (see mobile form-data).
  String get remark =>
      this == AttendanceSubmitKind.checkIn ? 'checkin' : 'checkout';

  String get timeFieldName =>
      this == AttendanceSubmitKind.checkIn ? 'check_in_at' : 'check_out_at';

  String get path => this == AttendanceSubmitKind.checkIn
      ? '/attendances/check_in'
      : '/attendances/check_out';
}
