import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/api/api_provider.dart';
import 'package:flutter_synergy/features/attendance/attendance_service.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final api = ref.watch(apiClientProvider);
  return AttendanceService(api);
});
