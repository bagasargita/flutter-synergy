import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:dio/dio.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class ShiftInfo {
  final String startTime;
  final String endTime;
  final String status;

  const ShiftInfo({
    required this.startTime,
    required this.endTime,
    required this.status,
  });
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
  final ShiftInfo shift;
  final List<QuickAction> quickActions;
  final List<ActivityItem> recentActivities;
  final List<Announcement> announcements;

  const DashboardData({
    required this.shift,
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

      return const DashboardData(
        shift: ShiftInfo(
          startTime: '08:30 AM',
          endTime: '05:30 PM',
          status: 'On Time',
        ),
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
