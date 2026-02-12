import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/api/api_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_controller.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';

/// Provides [DashboardService] – the API layer for dashboard data.
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardService(apiClient);
});

/// Provides [DashboardController] – the state layer for the dashboard.
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final service = ref.watch(dashboardServiceProvider);
  return DashboardController(service);
});
