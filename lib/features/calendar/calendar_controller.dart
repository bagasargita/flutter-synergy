import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/calendar/calendar_service.dart';

class CalendarState {
  final bool isLoading;
  final CalendarMonthData? data;
  final String? errorMessage;

  const CalendarState({this.isLoading = false, this.data, this.errorMessage});

  CalendarState copyWith({
    bool? isLoading,
    CalendarMonthData? data,
    String? errorMessage,
  }) {
    return CalendarState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

class CalendarController extends StateNotifier<CalendarState> {
  final CalendarService _service;

  CalendarController(this._service) : super(const CalendarState()) {
    loadCurrentMonth();
  }

  Future<void> loadCurrentMonth() async {
    final now = DateTime.now();
    await loadMonth(now.year, now.month);
  }

  /// Loads `/attendances/monthly?start_date=YYYY-MM-01` and `/calendar_legends` for [year]/[month].
  Future<void> loadMonth(int year, int month) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await _service.fetchMonth(
        year: year,
        month: month,
        today: DateTime.now(),
      );
      state = state.copyWith(isLoading: false, data: data);
      AppLogger.info('Calendar month loaded: $year-$month');
    } catch (e, st) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      AppLogger.error('Failed to load calendar data', error: e, stackTrace: st);
    }
  }

  Future<void> loadPreviousMonth() async {
    final current = state.data;
    if (current == null || current.days.isEmpty) return;
    final first = current.days.first.date;
    var y = first.year;
    var m = first.month - 1;
    if (m < 1) {
      m = 12;
      y--;
    }
    await loadMonth(y, m);
  }

  Future<void> loadNextMonth() async {
    final current = state.data;
    if (current == null || current.days.isEmpty) return;
    final first = current.days.first.date;
    var y = first.year;
    var m = first.month + 1;
    if (m > 12) {
      m = 1;
      y++;
    }
    await loadMonth(y, m);
  }

  /// Reloads the month currently on screen (pull-to-refresh).
  Future<void> refresh() async {
    final data = state.data;
    if (data != null && data.days.isNotEmpty) {
      final d = data.days.first.date;
      await loadMonth(d.year, d.month);
    } else {
      await loadCurrentMonth();
    }
  }

  void selectDay(CalendarDayInfo day) {
    final current = state.data;
    if (current == null) return;

    final updatedDays = current.days
        .map((d) => d.copyWith(isSelected: d.date == day.date))
        .toList(growable: false);

    final selected = updatedDays.firstWhere(
      (d) => d.isSelected,
      orElse: () => updatedDays.first,
    );

    final attendance = _service.buildAttendanceForDay(selected);

    state = state.copyWith(
      data: CalendarMonthData(
        monthLabel: current.monthLabel,
        days: updatedDays,
        selectedDay: selected,
        dayAttendance: attendance,
        timesheetHours: _service.timesheetDisplayFor(selected),
        legends: current.legends,
      ),
    );
  }
}
