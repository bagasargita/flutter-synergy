import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:dio/dio.dart';

/// Data model for a single dashboard item.
class DashboardItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;

  const DashboardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory DashboardItem.fromJson(Map<String, dynamic> json) {
    return DashboardItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      status: json['status'] as String,
    );
  }
}

/// Handles dashboard-related API calls.
class DashboardService {
  // ignore: unused_field
  final ApiClient _api; // Will be used with real API endpoints.

  DashboardService(this._api);

  /// Fetches dashboard items. Uses mock data in dev mode.
  Future<List<DashboardItem>> fetchDashboardItems() async {
    try {
      // --- Mock implementation ---
      await Future<void>.delayed(const Duration(seconds: 1));

      return List.generate(
        15,
        (i) => DashboardItem(
          id: 'item_${i + 1}',
          title: 'Dashboard Item ${i + 1}',
          subtitle: 'Updated ${i + 1} hours ago',
          status: i % 3 == 0
              ? 'active'
              : i % 3 == 1
                  ? 'pending'
                  : 'completed',
        ),
      );

      // --- Real implementation ---
      // final response = await _api.get('/dashboard/items');
      // final list = response.data['data'] as List;
      // return list.map((e) => DashboardItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
