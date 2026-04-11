import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/features/calendar/calendar_models.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:dio/dio.dart';

class CalendarService {
  final ApiClient _api;

  CalendarService(this._api);

  Future<CalendarMonthData> fetchCurrentMonth() async {
    final now = DateTime.now();
    return fetchMonth(year: now.year, month: now.month, today: now);
  }

  Future<CalendarMonthData> fetchMonth({
    required int year,
    required int month,
    DateTime? today,
  }) async {
    try {
      final todayResolved = today ?? DateTime.now();
      final startDate = _ymd(DateTime(year, month, 1));

      final responses = await Future.wait([
        _api.get<Map<String, dynamic>>(
          '/attendances/monthly',
          queryParameters: {'start_date': startDate},
        ),
        _api.get<Map<String, dynamic>>('/calendar_legends'),
      ]);

      final monthlyRes = responses[0];
      final legendsRes = responses[1];

      final monthlyBody = monthlyRes.data ?? <String, dynamic>{};
      if (monthlyBody['success'] != true) {
        throw ApiException(
          message:
              (monthlyBody['message'] ?? 'Failed to load monthly attendance.')
                  .toString(),
          statusCode: monthlyRes.statusCode,
          data: monthlyBody,
        );
      }

      final legendsBody = legendsRes.data ?? <String, dynamic>{};
      if (legendsBody['success'] != true) {
        throw ApiException(
          message:
              (legendsBody['message'] ?? 'Failed to load calendar legends.')
                  .toString(),
          statusCode: legendsRes.statusCode,
          data: legendsBody,
        );
      }

      final legends = _parseLegends(
        legendsBody['data'] as List<dynamic>? ?? [],
      );
      final rows = monthlyBody['data'] as List<dynamic>? ?? [];
      final byDate = <String, Map<String, dynamic>>{};
      for (final e in rows) {
        if (e is Map<String, dynamic>) {
          byDate[(e['date'] ?? '').toString()] = e;
        } else if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          byDate[(m['date'] ?? '').toString()] = m;
        }
      }

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
      final daysInMonth = DateUtils.getDaysInMonth(year, month);

      final days = <CalendarDayInfo>[];
      for (var d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, month, d);
        final key = _ymd(date);
        final row = byDate[key] ?? <String, dynamic>{};
        final isToday = _isSameDate(date, todayResolved);

        final holidayRaw = row['holiday'];
        final holidayStr = holidayRaw?.toString().trim();
        final hasHoliday = holidayStr != null && holidayStr.isNotEmpty;

        days.add(
          CalendarDayInfo(
            date: date,
            isToday: isToday,
            isSelected: false,
            dayType: hasHoliday ? 'PUBLIC_HOLIDAY' : 'WORKING_DAY',
            holidayName: hasHoliday ? holidayStr : null,
            legendKeys: _resolveLegendKeys(isToday: isToday, row: row),
            attendanceRow: row.isEmpty ? null : row,
          ),
        );
      }

      final selectedIndex = days.indexWhere((e) => e.isToday);
      final idx = selectedIndex >= 0 ? selectedIndex : 0;
      for (var i = 0; i < days.length; i++) {
        days[i] = days[i].copyWith(isSelected: i == idx);
      }
      final selectedDay = days[idx];

      return CalendarMonthData(
        monthLabel: monthLabel,
        days: days,
        selectedDay: selectedDay,
        dayAttendance: buildAttendanceForDay(selectedDay),
        timesheetHours: _timesheetLabel(selectedDay.attendanceRow),
        legends: legends,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  List<CalendarLegendItem> _parseLegends(List<dynamic> raw) {
    final out = <CalendarLegendItem>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final name = (m['name'] ?? '').toString();
      final label = (m['label'] ?? name).toString();
      final status = m['status']?.toString();
      final colorHex = (m['color'] ?? '#888888').toString();
      final symRaw = m['symbol'];
      final symbolStr = symRaw?.toString().trim();
      final symbol = _normalizeSymbol(
        name: name,
        status: status,
        rawSymbol: symbolStr,
      );
      final key = (status == null || status.isEmpty) ? name : '$name|$status';
      if (name.isEmpty) continue;
      out.add(
        CalendarLegendItem(
          key: key,
          label: label,
          dotColor: _parseHexColor(colorHex),
          symbol: symbol,
        ),
      );
    }
    return out;
  }

  Color _parseHexColor(String hex) {
    var h = hex.trim().replaceFirst('#', '');
    // Support CSS shorthand from API, e.g. "#888" -> "#888888".
    if (h.length == 3) {
      h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
    }
    if (h.length == 6) {
      h = 'FF$h';
    }
    final v = int.tryParse(h, radix: 16);
    if (v == null) return const Color(0xFF888888);
    return Color(v);
  }

  String? _normalizeSymbol({
    required String name,
    required String? status,
    required String? rawSymbol,
  }) {
    final normalized = rawSymbol?.toLowerCase();
    if (normalized == 'circle' ||
        normalized == 'triangle' ||
        normalized == 'square') {
      return normalized;
    }
    // Keep unapproved request legends visually consistent when API omits symbol.
    if ((status ?? '').toLowerCase() == 'unapproved') {
      if (name == 'trip') return 'triangle';
      if (name == 'overtime') return 'square';
      if (name == 'leave') return 'circle';
    }
    return null;
  }

  String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isEmptyNested(dynamic v) {
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is Map) return v.isEmpty;
    return false;
  }

  String? _nestedStatus(dynamic v) {
    if (_isEmptyNested(v)) return null;
    if (v is Map) {
      final s = v['status'] ?? v['state'];
      if (s != null && s.toString().trim().isNotEmpty) {
        return s.toString().toLowerCase();
      }
      return 'approved';
    }
    if (v is String && v.trim().isNotEmpty) {
      return v.trim().toLowerCase();
    }
    return 'approved';
  }

  /// All applicable legend keys for the day (multiple marks when e.g. leave + late).
  /// Order: trip, leave, overtime, holiday, attendance; `today` only if nothing else applies.
  List<String> _resolveLegendKeys({
    required bool isToday,
    required Map<String, dynamic> row,
  }) {
    final keys = <String>[];

    final trip = row['trip'];
    if (!_isEmptyNested(trip)) {
      final tripSt = _nestedStatus(trip) ?? 'approved';
      keys.add('trip|$tripSt');
    }

    final leave = row['leave'];
    if (!_isEmptyNested(leave)) {
      final leaveSt = _nestedStatus(leave) ?? 'approved';
      keys.add('leave|$leaveSt');
    }

    final overtime = row['overtime'];
    if (!_isEmptyNested(overtime)) {
      final otSt = _nestedStatus(overtime) ?? 'approved';
      keys.add('overtime|$otSt');
    }

    final holiday = row['holiday'];
    final holStr = holiday?.toString().trim();
    if (holStr != null && holStr.isNotEmpty) {
      keys.add('holiday');
    }

    final attendance = row['attendance']?.toString().toLowerCase();
    if (attendance != null && attendance.isNotEmpty) {
      if (attendance == 'late') keys.add('attendance|late');
      if (attendance == 'underhour') keys.add('attendance|underhour');
      if (attendance == 'absence') keys.add('attendance|absence');
    }

    if (keys.isEmpty && isToday) {
      keys.add('today');
    }

    return keys;
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

  String _primaryActionFromRow(Map<String, dynamic> data) {
    final checkInRaw = data['check_in']?.toString() ?? '';
    final checkOutRaw = data['check_out']?.toString() ?? '';
    final hasIn = checkInRaw.isNotEmpty;
    final hasOut = checkOutRaw.isNotEmpty;
    if (!hasIn) return 'Check In';
    if (!hasOut) return 'Check Out';
    return 'Attendance';
  }

  String _timesheetLabel(Map<String, dynamic>? row) {
    if (row == null) return '-';
    final t = row['timesheet']?.toString();
    if (t == null || t.isEmpty) return '-';
    return t;
  }

  /// Timesheet column for the day summary card.
  String timesheetDisplayFor(CalendarDayInfo day) =>
      _timesheetLabel(day.attendanceRow);

  /// Builds [DailyAttendanceInfo] for the selected calendar day.
  DailyAttendanceInfo buildAttendanceForDay(CalendarDayInfo day) {
    final dateLabel =
        '${_formatMonthShort(day.date.month)} ${day.date.day}, ${day.date.year}';
    final row = day.attendanceRow;
    if (row == null || row.isEmpty) {
      return DailyAttendanceInfo(
        date: dateLabel,
        holidayName: day.holidayName,
        dayType: day.dayType,
        checkIn: null,
        checkOut: null,
        primaryAction: 'Check In',
      );
    }

    final holidayStr = row['holiday']?.toString().trim();
    final hasHoliday = holidayStr != null && holidayStr.isNotEmpty;

    return DailyAttendanceInfo(
      date: dateLabel,
      holidayName: hasHoliday ? holidayStr : null,
      dayType: hasHoliday ? 'PUBLIC_HOLIDAY' : 'WORKING_DAY',
      checkIn: _formatIsoTimeTo12h(row['check_in']?.toString()),
      checkOut: _formatIsoTimeTo12h(row['check_out']?.toString()),
      primaryAction: _primaryActionFromRow(row),
      attendanceStatus: (row['attendance'] ?? '').toString().trim().isEmpty
          ? null
          : row['attendance'].toString(),
      timesheet: (row['timesheet'] ?? '').toString().trim().isEmpty
          ? null
          : row['timesheet'].toString(),
    );
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
