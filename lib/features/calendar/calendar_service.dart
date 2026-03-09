import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:dio/dio.dart';

/// Service responsible for providing calendar data.
///
/// Currently returns mock data for the current month, but is wired
/// with [ApiClient] so it can be hooked to a real backend later.
class CalendarService {
  // ignore: unused_field
  final ApiClient _api;

  CalendarService(this._api);

  Future<CalendarMonthData> fetchCurrentMonth() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      const monthNamesLong = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final monthLabel = '${monthNamesLong[month - 1]} $year';

      // Generate all days in current month.
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      final List<CalendarDayInfo> days = List.generate(daysInMonth, (index) {
        final date = DateTime(year, month, index + 1);
        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        // Simple mock: 22nd is a public holiday, others working days.
        final bool isHoliday = date.day == 22;

        return CalendarDayInfo(
          date: date,
          isToday: isToday,
          isSelected: isToday,
          dayType: isHoliday ? 'PUBLIC_HOLIDAY' : 'WORKING_DAY',
          holidayName: isHoliday ? 'Tahun Baru Imlek 2577' : null,
          legendKey: isHoliday
              ? 'public_holiday'
              : isToday
              ? 'today'
              : null,
        );
      });

      final selectedDay = days.firstWhere(
        (d) => d.isSelected,
        orElse: () => days.first,
      );

      final dayAttendance = buildAttendanceForDay(selectedDay);

      final legends = <CalendarLegendItem>[
        const CalendarLegendItem(
          key: 'today',
          label: 'Today',
          dotColor: Color(0xFF1A73E8),
        ),
        const CalendarLegendItem(
          key: 'late_checkin',
          label: 'Late Check-in',
          dotColor: Color(0xFFF4B400),
        ),
        const CalendarLegendItem(
          key: 'leave',
          label: 'Leave',
          dotColor: Color(0xFF34A853),
        ),
        const CalendarLegendItem(
          key: 'public_holiday',
          label: 'Public Holiday',
          dotColor: Color(0xFFEA4335),
        ),
        const CalendarLegendItem(
          key: 'absence',
          label: 'Absence',
          dotColor: Color(0xFF9E9E9E),
        ),
        const CalendarLegendItem(
          key: 'trip',
          label: 'Trip Arrangement',
          dotColor: Color(0xFF5C6BC0),
        ),
      ];

      return CalendarMonthData(
        monthLabel: monthLabel,
        days: days,
        selectedDay: selectedDay,
        dayAttendance: dayAttendance,
        timesheetHours: '08:00 hrs',
        legends: legends,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Builds a simple [DailyAttendanceInfo] for the given day.
  DailyAttendanceInfo buildAttendanceForDay(CalendarDayInfo day) {
    final dateLabel =
        '${_formatMonthShort(day.date.month)} ${day.date.day}, ${day.date.year}';

    if (day.dayType == 'PUBLIC_HOLIDAY') {
      return DailyAttendanceInfo(
        date: dateLabel,
        holidayName: day.holidayName,
        dayType: 'PUBLIC_HOLIDAY',
        checkIn: null,
        checkOut: null,
        primaryAction: 'Check In',
      );
    }

    return const DailyAttendanceInfo(
      date: '',
      holidayName: null,
      dayType: 'WORKING_DAY',
      checkIn: '08:00 AM',
      checkOut: '05:00 PM',
      primaryAction: 'Check Out',
    ).copyWith(date: dateLabel);
  }

  String _formatMonthShort(int month) {
    const monthNamesShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNamesShort[month - 1];
  }
}
