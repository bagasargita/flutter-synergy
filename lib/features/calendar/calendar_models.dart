import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';

/// Represents a single day in the calendar month grid.
class CalendarDayInfo {
  final DateTime date;
  final bool isToday;
  final bool isSelected;

  /// e.g. 'PUBLIC_HOLIDAY', 'WORKING_DAY'
  final String dayType;

  /// Optional holiday name (e.g. weekend label or full holiday title).
  final String? holidayName;

  /// Legend keys for icons under the day (e.g. `leave|approved`, `attendance|late`).
  /// Multiple keys show multiple marks; `holiday` still uses number color only (no dot).
  /// Stored nullable so tests / fakes cannot violate the type; use [legendKeys] getter.
  final List<String>? _legendKeys;

  /// Always non-null (empty when unset). Safe for mocks that would otherwise return null.
  List<String> get legendKeys => _legendKeys ?? const [];

  /// Raw row from `GET /attendances/monthly` for the selected day summary.
  final Map<String, dynamic>? attendanceRow;

  const CalendarDayInfo({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.dayType,
    this.holidayName,
    List<String>? legendKeys,
    this.attendanceRow,
  }) : _legendKeys = legendKeys;

  CalendarDayInfo copyWith({
    bool? isSelected,
    Map<String, dynamic>? attendanceRow,
  }) {
    return CalendarDayInfo(
      date: date,
      isToday: isToday,
      isSelected: isSelected ?? this.isSelected,
      dayType: dayType,
      holidayName: holidayName,
      legendKeys: _legendKeys,
      attendanceRow: attendanceRow ?? this.attendanceRow,
    );
  }
}

/// Legend row from `/calendar_legends` (and dots under month cells).
class CalendarLegendItem {
  /// Lookup key, e.g. `today`, `holiday`, `attendance|late`, `trip|approved`.
  final String key;
  final String label;
  final Color dotColor;

  /// `circle`, `triangle`, or `square` from API; defaults to circle.
  final String? symbol;

  const CalendarLegendItem({
    required this.key,
    required this.label,
    required this.dotColor,
    this.symbol,
  });
}

/// Aggregated data for a calendar month screen.
class CalendarMonthData {
  final String monthLabel;
  final List<CalendarDayInfo> days;
  final CalendarDayInfo selectedDay;
  final DailyAttendanceInfo dayAttendance;
  final String timesheetHours;
  final List<CalendarLegendItem> legends;

  const CalendarMonthData({
    required this.monthLabel,
    required this.days,
    required this.selectedDay,
    required this.dayAttendance,
    required this.timesheetHours,
    required this.legends,
  });
}
