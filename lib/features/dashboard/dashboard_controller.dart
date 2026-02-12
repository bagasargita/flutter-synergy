import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';

/// State for the dashboard feature.
class DashboardState {
  final bool isLoading;
  final List<DashboardItem> items;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    List<DashboardItem>? items,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier for the dashboard page.
///
/// Handles initial load and pull-to-refresh.
class DashboardController extends StateNotifier<DashboardState> {
  final DashboardService _service;

  DashboardController(this._service) : super(const DashboardState()) {
    loadItems();
  }

  /// Fetches items from the service.
  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final items = await _service.fetchDashboardItems();
      state = state.copyWith(isLoading: false, items: items);
      AppLogger.info('Dashboard loaded ${items.length} items');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      AppLogger.error('Failed to load dashboard', error: e);
    }
  }

  /// Pull-to-refresh handler – same as [loadItems] but can be
  /// awaited by [RefreshIndicator].
  Future<void> refresh() => loadItems();
}
