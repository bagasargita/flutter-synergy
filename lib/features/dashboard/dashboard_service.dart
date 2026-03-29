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
  /// Remote banner URL from `/articles` API (`file_url`).
  final String? fileUrl;

  const Announcement({
    required this.id,
    required this.title,
    this.date = '',
    this.imageAsset,
    this.fileUrl,
  });
}

/// Fixes URLs like `https://sbs...comhttps://storage...` from the API.
String? normalizeArticleFileUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  const prefix = 'https://sbs.synergyengineering.comhttps://';
  if (raw.startsWith(prefix)) {
    return 'https://${raw.substring(prefix.length)}';
  }
  return raw;
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
  final ApiClient _api;

  DashboardService(this._api);

  Future<DashboardData> fetchDashboardData() async {
    try {
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
      final responses = await Future.wait([
        _api.get<Map<String, dynamic>>('/attendances/monthly_summary'),
        _api.get<Map<String, dynamic>>(
          '/articles',
          queryParameters: {'page': 1},
        ),
      ]);
      final monthlySummaryResponse = responses[0];
      final articlesResponse = responses[1];
      final monthlySummaryBody =
          monthlySummaryResponse.data ?? <String, dynamic>{};
      final monthlySummarySuccess = monthlySummaryBody['success'] == true;

      if (!monthlySummarySuccess) {
        throw ApiException(
          message: (monthlySummaryBody['message'] ??
                  'Failed to load monthly attendance summary.')
              .toString(),
          statusCode: monthlySummaryResponse.statusCode,
          data: monthlySummaryBody,
        );
      }

      final monthlySummaryData =
          monthlySummaryBody['data'] as Map<String, dynamic>? ??
              <String, dynamic>{};
      final lateness = (monthlySummaryData['lateness'] as num?)?.toInt() ?? 0;
      final shortOfWorkhours =
          (monthlySummaryData['short_of_workhours'] as num?)?.toInt() ?? 0;
      final absences = (monthlySummaryData['absences'] as num?)?.toInt() ?? 0;
      final works = (monthlySummaryData['works'] as num?)?.toInt() ?? 0;
      final timesheets = (monthlySummaryData['timesheets'] ?? '00:00').toString();

      final articlesBody = articlesResponse.data ?? <String, dynamic>{};
      final articlesSuccess = articlesBody['success'] == true;
      if (!articlesSuccess) {
        throw ApiException(
          message: (articlesBody['message'] ?? 'Failed to load articles.')
              .toString(),
          statusCode: articlesResponse.statusCode,
          data: articlesBody,
        );
      }
      final articlesData =
          articlesBody['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final articlesList = articlesData['articles'] as List<dynamic>? ?? [];
      final announcements = <Announcement>[];
      for (var i = 0; i < articlesList.length; i++) {
        final item = articlesList[i];
        if (item is! Map<String, dynamic>) continue;
        final title = (item['title'] ?? '').toString();
        final fileUrl = normalizeArticleFileUrl(
          (item['file_url'] ?? '').toString(),
        );
        announcements.add(
          Announcement(
            id: 'article_$i',
            title: title,
            fileUrl: fileUrl,
          ),
        );
      }

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
          lateCheckinEarlyCheckout: lateness,
          shortWorkhours: shortOfWorkhours,
          absences: absences,
          works: works,
          monthLabel: monthLabelStr,
        ),
        totalTimesheet: TotalTimesheetInfo(totalHours: timesheets),
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
        announcements: announcements,
      );

    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
