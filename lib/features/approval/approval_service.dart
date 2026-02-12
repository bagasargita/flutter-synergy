import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:dio/dio.dart';

/// Possible statuses for an approval request.
enum ApprovalStatus { pending, approved, rejected }

/// Data model for a single approval item.
class ApprovalItem {
  final String id;
  final String title;
  final String requester;
  final DateTime requestedAt;
  final ApprovalStatus status;

  const ApprovalItem({
    required this.id,
    required this.title,
    required this.requester,
    required this.requestedAt,
    required this.status,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      id: json['id'] as String,
      title: json['title'] as String,
      requester: json['requester'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
    );
  }
}

/// Handles approval-related API calls.
class ApprovalService {
  // ignore: unused_field
  final ApiClient _api; // Will be used with real API endpoints.

  ApprovalService(this._api);

  /// Fetches the list of approval requests. Uses mock data for now.
  Future<List<ApprovalItem>> fetchApprovals() async {
    try {
      // --- Mock implementation ---
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final now = DateTime.now();
      return [
        ApprovalItem(
          id: 'apr_001',
          title: 'Budget Increase – Marketing Q2',
          requester: 'Alice Johnson',
          requestedAt: now.subtract(const Duration(hours: 2)),
          status: ApprovalStatus.pending,
        ),
        ApprovalItem(
          id: 'apr_002',
          title: 'New Hire – Backend Engineer',
          requester: 'Bob Williams',
          requestedAt: now.subtract(const Duration(hours: 5)),
          status: ApprovalStatus.approved,
        ),
        ApprovalItem(
          id: 'apr_003',
          title: 'Travel Request – Client Visit',
          requester: 'Carol Martinez',
          requestedAt: now.subtract(const Duration(days: 1)),
          status: ApprovalStatus.pending,
        ),
        ApprovalItem(
          id: 'apr_004',
          title: 'Software License – Figma',
          requester: 'Dan Lee',
          requestedAt: now.subtract(const Duration(days: 2)),
          status: ApprovalStatus.rejected,
        ),
        ApprovalItem(
          id: 'apr_005',
          title: 'Office Supplies Reorder',
          requester: 'Eve Chen',
          requestedAt: now.subtract(const Duration(days: 3)),
          status: ApprovalStatus.approved,
        ),
      ];

      // --- Real implementation ---
      // final response = await _api.get('/approvals');
      // final list = response.data['data'] as List;
      // return list.map((e) => ApprovalItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
