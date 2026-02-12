import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/features/approval/approval_service.dart';

/// State for the approval feature.
class ApprovalState {
  final bool isLoading;
  final List<ApprovalItem> items;
  final String? errorMessage;

  const ApprovalState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
  });

  ApprovalState copyWith({
    bool? isLoading,
    List<ApprovalItem>? items,
    String? errorMessage,
  }) {
    return ApprovalState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier for the approval list.
class ApprovalController extends StateNotifier<ApprovalState> {
  final ApprovalService _service;

  ApprovalController(this._service) : super(const ApprovalState()) {
    loadApprovals();
  }

  Future<void> loadApprovals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final items = await _service.fetchApprovals();
      state = state.copyWith(isLoading: false, items: items);
      AppLogger.info('Loaded ${items.length} approvals');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      AppLogger.error('Failed to load approvals', error: e);
    }
  }

  Future<void> refresh() => loadApprovals();
}
