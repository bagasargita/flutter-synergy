import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/widgets/async_value_widget.dart'
    show ErrorDisplayWidget, LoadingWidget;
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/calendar/calendar_provider.dart';
import 'package:flutter_synergy/features/calendar/widgets/calendar_day_summary_card.dart';
import 'package:flutter_synergy/features/calendar/widgets/calendar_legend_section.dart';
import 'package:flutter_synergy/features/calendar/widgets/calendar_month_view.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_header.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

class CalendarTab extends ConsumerWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final fullName = authState.profile?.fullName;
    final userName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (authState.user?.name ?? 'User');

    if (state.isLoading && state.data == null) {
      return const Scaffold(
        backgroundColor: DashboardTheme.bgColor,
        body: Center(child: LoadingWidget()),
      );
    }

    if (state.errorMessage != null && state.data == null) {
      return Scaffold(
        backgroundColor: DashboardTheme.bgColor,
        body: Center(
          child: ErrorDisplayWidget(
            message: state.errorMessage!,
            onRetry: () => ref
                .read(calendarControllerProvider.notifier)
                .loadCurrentMonth(),
          ),
        ),
      );
    }

    final data = state.data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      color: DashboardTheme.accentBlue,
      onRefresh: () => ref.read(calendarControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),
          DashboardHeader(
            userName: userName,
            title: 'My Calendar',
            avatarUrl: authState.profile?.avatar,
            initial: authState.profile?.initial,
          ),
          const SizedBox(height: 20),
          CalendarMonthView(
            data: data,
            isLoadingMonth: state.isLoading,
            onPreviousMonth: () => ref
                .read(calendarControllerProvider.notifier)
                .loadPreviousMonth(),
            onNextMonth: () =>
                ref.read(calendarControllerProvider.notifier).loadNextMonth(),
            onDaySelected: (day) =>
                ref.read(calendarControllerProvider.notifier).selectDay(day),
          ),
          const SizedBox(height: 16),
          CalendarDaySummaryCard(
            attendance: data.dayAttendance,
            timesheetHours: data.timesheetHours,
          ),
          const SizedBox(height: 24),
          CalendarLegendSection(items: data.legends),
        ],
      ),
    );
  }
}
