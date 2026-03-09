import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/api/api_provider.dart';
import 'package:flutter_synergy/features/calendar/calendar_controller.dart';
import 'package:flutter_synergy/features/calendar/calendar_service.dart';

/// Provides [CalendarService] – the API layer for calendar data.
final calendarServiceProvider = Provider<CalendarService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CalendarService(apiClient);
});

/// Provides [CalendarController] – the state layer for the calendar tab.
final calendarControllerProvider =
    StateNotifierProvider<CalendarController, CalendarState>((ref) {
      final service = ref.watch(calendarServiceProvider);
      return CalendarController(service);
    });
