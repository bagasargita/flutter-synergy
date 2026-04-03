import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:dio/dio.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Daily check-in/out card: date, holiday, check-in/out times, primary action.
class DailyAttendanceInfo {
  final String date;
  final String? holidayName;
  final String dayType; // 'PUBLIC_HOLIDAY' | 'WORKING_DAY'
  final String? checkIn; // e.g. '7:30 AM' or null
  final String? checkOut;
  final String primaryAction; // 'Check In' | 'Check Out' | 'Attendance'
  /// API `attendance` field, e.g. `underhour`.
  final String? attendanceStatus;

  /// API `timesheet` duration for the day, e.g. `03:00`.
  final String? timesheet;

  const DailyAttendanceInfo({
    required this.date,
    this.holidayName,
    required this.dayType,
    this.checkIn,
    this.checkOut,
    required this.primaryAction,
    this.attendanceStatus,
    this.timesheet,
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
    String? attendanceStatus,
    String? timesheet,
  }) {
    return DailyAttendanceInfo(
      date: date ?? this.date,
      holidayName: holidayName ?? this.holidayName,
      dayType: dayType ?? this.dayType,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      primaryAction: primaryAction ?? this.primaryAction,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      timesheet: timesheet ?? this.timesheet,
    );
  }
}

String _formatDashboardDateParam(DateTime local) {
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String? _formatIsoTimeTo12h(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return null;
  final t = parsed.toLocal();
  var h = t.hour;
  final min = t.minute;
  final period = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h == 0) h = 12;
  final mm = min.toString().padLeft(2, '0');
  return '$h:$mm $period';
}

bool _isHolidayPresent(dynamic holiday) {
  if (holiday == null) return false;
  if (holiday is String) return holiday.trim().isNotEmpty;
  if (holiday is Map) return holiday.isNotEmpty;
  return true;
}

String? _holidayLabel(dynamic holiday) {
  if (holiday == null) return null;
  if (holiday is String) {
    final s = holiday.trim();
    return s.isEmpty ? null : s;
  }
  if (holiday is Map) {
    final m = Map<String, dynamic>.from(holiday);
    for (final key in ['name', 'title', 'label']) {
      final v = m[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
  }
  return null;
}

String _primaryActionFromDailyPayload(Map<String, dynamic> data) {
  final checkInRaw = data['check_in']?.toString() ?? '';
  final checkOutRaw = data['check_out']?.toString() ?? '';
  final hasIn = checkInRaw.isNotEmpty;
  final hasOut = checkOutRaw.isNotEmpty;
  if (!hasIn) return 'Check In';
  if (!hasOut) return 'Check Out';
  return 'Attendance';
}

/// When `/attendances/daily` returns 404 (no record yet), show a normal "Check In" card.
DailyAttendanceInfo _emptyDailyAttendanceForDate(String headerDateLabel) {
  return DailyAttendanceInfo(
    date: headerDateLabel,
    holidayName: null,
    dayType: 'WORKING_DAY',
    checkIn: null,
    checkOut: null,
    primaryAction: 'Check In',
    attendanceStatus: null,
    timesheet: null,
  );
}

DailyAttendanceInfo _mapDailyAttendanceToCard({
  required Map<String, dynamic> data,
  required String headerDateLabel,
}) {
  final holidayRaw = data['holiday'];
  final isHoliday = _isHolidayPresent(holidayRaw);
  final holidayName = _holidayLabel(holidayRaw);
  final attendanceStatus = (data['attendance'] ?? '').toString().trim().isEmpty
      ? null
      : data['attendance'].toString();
  final timesheet = (data['timesheet'] ?? '').toString().trim().isEmpty
      ? null
      : data['timesheet'].toString();

  return DailyAttendanceInfo(
    date: headerDateLabel,
    holidayName: holidayName,
    dayType: isHoliday ? 'PUBLIC_HOLIDAY' : 'WORKING_DAY',
    checkIn: _formatIsoTimeTo12h(data['check_in']?.toString()),
    checkOut: _formatIsoTimeTo12h(data['check_out']?.toString()),
    primaryAction: _primaryActionFromDailyPayload(data),
    attendanceStatus: attendanceStatus,
    timesheet: timesheet,
  );
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

/// One page from `GET /articles?page=`.
class ArticlesPageResult {
  const ArticlesPageResult({required this.items, required this.hasMore});

  final List<Announcement> items;
  final bool hasMore;
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

List<Announcement> _announcementsFromArticlesJson(
  List<dynamic>? rawList,
  int page,
) {
  final articlesList = rawList ?? [];
  final out = <Announcement>[];
  for (var i = 0; i < articlesList.length; i++) {
    final item = articlesList[i];
    Map<String, dynamic>? m;
    if (item is Map<String, dynamic>) {
      m = item;
    } else if (item is Map) {
      m = Map<String, dynamic>.from(item);
    }
    if (m == null) continue;
    final title = (m['title'] ?? '').toString();
    final fileUrl = normalizeArticleFileUrl((m['file_url'] ?? '').toString());
    final idRaw = m['id'];
    final id = idRaw != null ? idRaw.toString() : 'p${page}_$i';
    var date = '';
    for (final k in ['published_at', 'created_at', 'date']) {
      final v = m[k]?.toString();
      if (v != null && v.trim().isNotEmpty) {
        date = v.trim();
        break;
      }
    }
    out.add(Announcement(id: id, title: title, date: date, fileUrl: fileUrl));
  }
  return out;
}

bool _articlesDataHasMore(Map<String, dynamic> data, int itemCount) {
  if (itemCount <= 0) return false;
  dynamic cur = data['current_page'];
  dynamic last = data['last_page'];
  if (cur == null || last == null) {
    final meta = data['meta'];
    if (meta is Map) {
      final mm = Map<String, dynamic>.from(meta);
      cur ??= mm['current_page'];
      last ??= mm['last_page'];
    }
  }
  if (cur is num && last is num) {
    return cur.toInt() < last.toInt();
  }
  final nextUrl = data['next_page_url'];
  if (nextUrl != null) {
    final s = nextUrl.toString();
    if (s.isNotEmpty && s != 'null') return true;
  }
  final links = data['links'];
  if (links is Map) {
    final next = links['next'];
    if (next != null) {
      final s = next.toString();
      if (s.isNotEmpty && s != 'null') return true;
    }
  }
  final perPage = data['per_page'];
  final limit = perPage is num && perPage > 0
      ? perPage.toInt()
      : AppConstants.defaultPageSize;
  return itemCount >= limit;
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

  /// Paginated `/articles` for the full announcements list (`page` is 1-based).
  Future<ArticlesPageResult> fetchArticlesPage(int page) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'must be >= 1');
    }
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/articles',
        queryParameters: {'page': page},
      );
      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw ApiException(
          message: (body['message'] ?? 'Failed to load articles.').toString(),
          statusCode: response.statusCode,
          data: body,
        );
      }
      final articlesData =
          body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final articlesList = articlesData['articles'] as List<dynamic>? ?? [];
      final items = _announcementsFromArticlesJson(articlesList, page);
      final hasMore = _articlesDataHasMore(articlesData, items.length);
      return ArticlesPageResult(items: items, hasMore: hasMore);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DailyAttendanceInfo> _fetchDailyAttendanceForDashboard({
    required String dateParam,
    required String headerDateLabel,
  }) async {
    try {
      final dailyAttendanceResponse = await _api.get<Map<String, dynamic>>(
        '/attendances/daily',
        queryParameters: {'date': dateParam},
      );
      final dailyBody = dailyAttendanceResponse.data ?? <String, dynamic>{};
      if (dailyBody['success'] == true) {
        final dailyData =
            dailyBody['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return _mapDailyAttendanceToCard(
          data: dailyData,
          headerDateLabel: headerDateLabel,
        );
      }
      final msg = (dailyBody['message'] ?? '').toString().toLowerCase();
      if (msg.contains('not found')) {
        return _emptyDailyAttendanceForDate(headerDateLabel);
      }
      throw ApiException(
        message: (dailyBody['message'] ?? 'Failed to load daily attendance.')
            .toString(),
        statusCode: dailyAttendanceResponse.statusCode,
        data: dailyBody,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _emptyDailyAttendanceForDate(headerDateLabel);
      }
      throw ApiException.fromDioException(e);
    }
  }

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
      final dateParam = _formatDashboardDateParam(now);
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
          message:
              (monthlySummaryBody['message'] ??
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
      final timesheets = (monthlySummaryData['timesheets'] ?? '00:00')
          .toString();

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
      final announcements = _announcementsFromArticlesJson(articlesList, 1);

      final dailyAttendance = await _fetchDailyAttendanceForDashboard(
        dateParam: dateParam,
        headerDateLabel: dateStr,
      );

      return DashboardData(
        dailyAttendance: dailyAttendance,
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
