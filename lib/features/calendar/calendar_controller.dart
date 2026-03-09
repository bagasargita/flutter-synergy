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
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await _service.fetchCurrentMonth();
      state = state.copyWith(isLoading: false, data: data);
      AppLogger.info('Calendar month data loaded');
    } catch (e, st) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      AppLogger.error('Failed to load calendar data', error: e, stackTrace: st);
    }
  }

  Future<void> refresh() => loadCurrentMonth();

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
        timesheetHours: current.timesheetHours,
        legends: current.legends,
      ),
    );
  }
}
