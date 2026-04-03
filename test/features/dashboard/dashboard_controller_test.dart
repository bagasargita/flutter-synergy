import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_controller.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardService extends Mock implements DashboardService {}

DashboardData _dashboardData() {
  return const DashboardData(
    dailyAttendance: DailyAttendanceInfo(
      date: 'Apr 3, 2026',
      dayType: 'WORKING_DAY',
      primaryAction: 'Check In',
    ),
    monthStats: MonthStats(
      lateCheckinEarlyCheckout: 1,
      shortWorkhours: 2,
      absences: 0,
      works: 18,
      monthLabel: 'April 2026',
    ),
    totalTimesheet: TotalTimesheetInfo(totalHours: '120:00'),
    quickActions: <QuickAction>[],
    recentActivities: <ActivityItem>[],
    announcements: <Announcement>[],
  );
}

void main() {
  late MockDashboardService service;

  setUp(() {
    service = MockDashboardService();
  });

  group('DashboardController', () {
    test('loads dashboard data successfully on startup', () async {
      when(
        () => service.fetchDashboardData(),
      ).thenAnswer((_) async => _dashboardData());

      final controller = DashboardController(service);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.data, isNotNull);
      expect(controller.state.data!.monthStats.works, 18);
    });

    test('sets error state when service throws', () async {
      when(
        () => service.fetchDashboardData(),
      ).thenThrow(const ApiException(message: 'Network down'));

      final controller = DashboardController(service);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.data, isNull);
      expect(controller.state.errorMessage, 'Network down');
    });

    test('refresh delegates to loadDashboard', () async {
      when(
        () => service.fetchDashboardData(),
      ).thenAnswer((_) async => _dashboardData());
      final controller = DashboardController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.refresh();

      verify(() => service.fetchDashboardData()).called(2);
    });
  });
}
