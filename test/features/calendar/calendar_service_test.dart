import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/calendar/calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

Response<Map<String, dynamic>> _response(
  Map<String, dynamic> data, {
  int statusCode = 200,
  String path = '/',
}) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: path),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  late MockApiClient api;
  late CalendarService service;

  setUp(() {
    api = MockApiClient();
    service = CalendarService(api);
  });

  group('CalendarService.fetchMonth', () {
    test('builds month data and parses legends', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          '/attendances/monthly',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _response(<String, dynamic>{
          'success': true,
          'data': <dynamic>[
            <String, dynamic>{
              'date': '2026-04-03',
              'attendance': 'late',
              'check_in': '2026-04-03T08:30:00+07:00',
              'check_out': '2026-04-03T17:31:00+07:00',
              'timesheet': '08:01',
            },
            <String, dynamic>{'date': '2026-04-05', 'holiday': 'Sunday'},
          ],
        }, path: '/attendances/monthly'),
      );
      when(() => api.get<Map<String, dynamic>>('/calendar_legends')).thenAnswer(
        (_) async => _response(<String, dynamic>{
          'success': true,
          'data': <dynamic>[
            <String, dynamic>{
              'name': 'today',
              'label': 'Today',
              'color': '#2563EB',
              'symbol': 'circle',
            },
            <String, dynamic>{
              'name': 'attendance',
              'status': 'late',
              'label': 'Late',
              'color': '#F59E0B',
              'symbol': 'triangle',
            },
          ],
        }, path: '/calendar_legends'),
      );

      final data = await service.fetchMonth(
        year: 2026,
        month: 4,
        today: DateTime(2026, 4, 3),
      );

      expect(data.monthLabel, 'April 2026');
      expect(data.days.length, 30);
      expect(data.selectedDay.date, DateTime(2026, 4, 3));
      expect(data.selectedDay.legendKeys, ['attendance|late']);
      expect(data.timesheetHours, '08:01');
      expect(data.legends.length, 2);
      expect(data.legends.first.dotColor, const Color(0xFF2563EB));
    });
  });

  group('CalendarService.buildAttendanceForDay', () {
    test('returns default check-in summary when day has no row', () {
      final day = CalendarDayInfo(
        date: DateTime(2026, 4, 1),
        isToday: false,
        isSelected: true,
        dayType: 'WORKING_DAY',
      );

      final summary = service.buildAttendanceForDay(day);

      expect(summary.primaryAction, 'Check In');
      expect(summary.checkIn, isNull);
      expect(summary.checkOut, isNull);
    });
  });
}
