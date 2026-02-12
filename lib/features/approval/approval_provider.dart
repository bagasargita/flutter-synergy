import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/api/api_provider.dart';
import 'package:flutter_synergy/features/approval/approval_controller.dart';
import 'package:flutter_synergy/features/approval/approval_service.dart';

/// Provides [ApprovalService] – the API layer for approvals.
final approvalServiceProvider = Provider<ApprovalService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApprovalService(apiClient);
});

/// Provides [ApprovalController] – the state layer for approvals.
final approvalControllerProvider =
    StateNotifierProvider<ApprovalController, ApprovalState>((ref) {
  final service = ref.watch(approvalServiceProvider);
  return ApprovalController(service);
});
