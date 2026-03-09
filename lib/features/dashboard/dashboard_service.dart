import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:dio/dio.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Daily check-in/out card: date, holiday, check-in/out times, primary action.
class DailyAttendanceInfo {
  final String date;
  final String? holidayName;
  final String dayType; // 'PUBLIC_HOLIDAY' | 'WORKING_DAY'
  final String? checkIn; // e.g. '08:00 AM' or null
  final String? checkOut;
  final String primaryAction; // 'Check In' | 'Check Out'

  const DailyAttendanceInfo({
    required this.date,
    this.holidayName,
    required this.dayType,
    this.checkIn,
    this.checkOut,
    required this.primaryAction,
  });
}

/// This Month stats: late check-in, short workhours, absences, works.
class MonthStats {
  final int lateCheckinEarlyCheckout;
  final int shortWorkhours;
  final int absences;
  final int works;
  final String monthLabel; // e.g. 'January 2026'

  const MonthStats({
    required this.lateCheckinEarlyCheckout,
    required this.shortWorkhours,
    required this.absences,
    required this.works,
    required this.monthLabel,
  });
}

/// Total timesheet summary.
class TotalTimesheetInfo {
  final String totalHours; // e.g. '28:00'

  const TotalTimesheetInfo({required this.totalHours});
}

extension DailyAttendanceCopy on DailyAttendanceInfo {
  DailyAttendanceInfo copyWith({
    String? date,
    String? holidayName,
    String? dayType,
    String? checkIn,
    String? checkOut,
    String? primaryAction,
  }) {
    return DailyAttendanceInfo(
      date: date ?? this.date,
      holidayName: holidayName ?? this.holidayName,
      dayType: dayType ?? this.dayType,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      primaryAction: primaryAction ?? this.primaryAction,
    );
  }
}

class QuickAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class Announcement {
  final String id;
  final String title;
  final String date;
  final String? imageAsset;

  const Announcement({
    required this.id,
    required this.title,
    required this.date,
    this.imageAsset,
  });
}

/// Aggregated response for the dashboard home screen.
class DashboardData {
  final DailyAttendanceInfo dailyAttendance;
  final MonthStats monthStats;
  final TotalTimesheetInfo totalTimesheet;
  final List<QuickAction> quickActions;
  final List<ActivityItem> recentActivities;
  final List<Announcement> announcements;

  const DashboardData({
    required this.dailyAttendance,
    required this.monthStats,
    required this.totalTimesheet,
    required this.quickActions,
    required this.recentActivities,
    required this.announcements,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class DashboardService {
  // ignore: unused_field
  final ApiClient _api; // Will be used with real API endpoints.

  DashboardService(this._api);

  Future<DashboardData> fetchDashboardData() async {
    try {
      // --- Mock implementation ---
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final now = DateTime.now();
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
      final dateStr =
          '${monthNamesShort[now.month - 1]} ${now.day}, ${now.year}';
      final monthLabelStr = '${monthNamesLong[now.month - 1]} ${now.year}';

      return DashboardData(
        dailyAttendance: DailyAttendanceInfo(
          date: dateStr,
          holidayName: null,
          dayType: 'WORKING_DAY',
          checkIn: null,
          checkOut: null,
          primaryAction: 'Check In',
        ),
        monthStats: MonthStats(
          lateCheckinEarlyCheckout: 0,
          shortWorkhours: 0,
          absences: 0,
          works: 0,
          monthLabel: monthLabelStr,
        ),
        totalTimesheet: TotalTimesheetInfo(totalHours: '28:00'),
        quickActions: [
          QuickAction(
            id: 'attendance',
            title: 'Attendance',
            subtitle: 'Check in & Check out',
            icon: Icons.access_time_rounded,
          ),
          QuickAction(
            id: 'calendar',
            title: 'My Calendar',
            subtitle: 'View your schedule',
            icon: Icons.calendar_today_rounded,
          ),
          QuickAction(
            id: 'timesheet',
            title: 'Timesheet',
            subtitle: 'Review Work\nWeekending',
            icon: Icons.assignment_rounded,
          ),
        ],
        recentActivities: [
          ActivityItem(
            id: 'act_1',
            title: 'Checked In',
            subtitle: 'Today, 08:24 AM',
            icon: Icons.login_rounded,
            color: Color(0xFF1A73E8),
          ),
          ActivityItem(
            id: 'act_2',
            title: 'Checked Out',
            subtitle: 'Yesterday, 05:32 PM',
            icon: Icons.logout_rounded,
            color: Color(0xFF34A853),
          ),
        ],
        announcements: [
          Announcement(
            id: 'ann_1',
            title: 'Grand Opening Indonesia Region',
            date: 'Oct 22, 2023',
          ),
          Announcement(
            id: 'ann_2',
            title: 'Company Annual Town Hall 2024',
            date: 'Jan 15, 2024',
          ),
        ],
      );

      // --- Real implementation ---
      // final response = await _api.get('/dashboard');
      // return DashboardData.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
