import 'package:flutter_synergy/features/calendar/calendar_controller.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/calendar/calendar_service.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarService extends Mock implements CalendarService {}

class FakeCalendarDayInfo extends Fake implements CalendarDayInfo {
  @override
  List<String> get legendKeys => const [];
}

DailyAttendanceInfo _attendance(String date) {
  return DailyAttendanceInfo(
    date: date,
    dayType: 'WORKING_DAY',
    primaryAction: 'Attendance',
    checkIn: '8:00 AM',
    checkOut: '5:00 PM',
  );
}

void main() {
  late MockCalendarService service;
  late CalendarDayInfo day1;
  late CalendarDayInfo day2;
  late CalendarMonthData monthData;

  setUpAll(() {
    registerFallbackValue(FakeCalendarDayInfo());
  });

  setUp(() {
    service = MockCalendarService();
    day1 = CalendarDayInfo(
      date: DateTime(2026, 4, 1),
      isToday: true,
      isSelected: true,
      dayType: 'WORKING_DAY',
      attendanceRow: const <String, dynamic>{'timesheet': '08:00'},
    );
    day2 = CalendarDayInfo(
      date: DateTime(2026, 4, 2),
      isToday: false,
      isSelected: false,
      dayType: 'WORKING_DAY',
      attendanceRow: const <String, dynamic>{'timesheet': '07:30'},
    );
    monthData = CalendarMonthData(
      monthLabel: 'April 2026',
      days: <CalendarDayInfo>[day1, day2],
      selectedDay: day1,
      dayAttendance: _attendance('Apr 1, 2026'),
      timesheetHours: '08:00',
      legends: const <CalendarLegendItem>[],
    );
  });

  group('CalendarController', () {
    test('loads current month on startup', () async {
      when(
        () => service.fetchMonth(
          year: any(named: 'year'),
          month: any(named: 'month'),
          today: any(named: 'today'),
        ),
      ).thenAnswer((_) async => monthData);
      when(
        () => service.buildAttendanceForDay(any()),
      ).thenReturn(_attendance(''));
      when(() => service.timesheetDisplayFor(any())).thenReturn('08:00');

      final controller = CalendarController(service);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.data?.monthLabel, 'April 2026');
    });

    test('selectDay updates selected day and summary', () async {
      when(
        () => service.fetchMonth(
          year: any(named: 'year'),
          month: any(named: 'month'),
          today: any(named: 'today'),
        ),
      ).thenAnswer((_) async => monthData);
      when(
        () => service.buildAttendanceForDay(any()),
      ).thenReturn(_attendance('Apr 2, 2026'));
      when(() => service.timesheetDisplayFor(any())).thenReturn('07:30');

      final controller = CalendarController(service);
      await Future<void>.delayed(Duration.zero);

      controller.selectDay(day2);

      final selected = controller.state.data!.selectedDay;
      expect(selected.date, day2.date);
      expect(selected.isSelected, isTrue);
      expect(controller.state.data!.timesheetHours, '07:30');
      expect(controller.state.data!.dayAttendance.date, 'Apr 2, 2026');
    });
  });
}
