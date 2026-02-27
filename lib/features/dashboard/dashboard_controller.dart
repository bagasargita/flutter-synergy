import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';

class DashboardState {
  final bool isLoading;
  final DashboardData? data;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardData? data,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardService _service;

  DashboardController(this._service) : super(const DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await _service.fetchDashboardData();
      state = state.copyWith(isLoading: false, data: data);
      AppLogger.info('Dashboard data loaded');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      AppLogger.error('Failed to load dashboard', error: e);
    }
  }

  Future<void> refresh() => loadDashboard();
}
