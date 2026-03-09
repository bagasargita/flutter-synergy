import 'package:flutter/material.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';

/// Represents a single day in the calendar month grid.
class CalendarDayInfo {
  final DateTime date;
  final bool isToday;
  final bool isSelected;

  /// e.g. 'PUBLIC_HOLIDAY', 'WORKING_DAY', 'ABSENCE', etc.
  final String dayType;

  /// Optional holiday name (e.g. 'Tahun Baru Imlek 2577').
  final String? holidayName;

  /// Key that maps to a legend item (e.g. 'today', 'late_checkin').
  final String? legendKey;

  const CalendarDayInfo({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.dayType,
    this.holidayName,
    this.legendKey,
  });

  CalendarDayInfo copyWith({bool? isSelected}) {
    return CalendarDayInfo(
      date: date,
      isToday: isToday,
      isSelected: isSelected ?? this.isSelected,
      dayType: dayType,
      holidayName: holidayName,
      legendKey: legendKey,
    );
  }
}

/// Legend configuration for dots under days and the LEGEND section.
class CalendarLegendItem {
  final String key;
  final String label;
  final Color dotColor;

  const CalendarLegendItem({
    required this.key,
    required this.label,
    required this.dotColor,
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
