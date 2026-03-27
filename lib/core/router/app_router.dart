import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/features/auth/auth_page.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_page.dart';
import 'package:flutter_synergy/features/attendance/attendance_page.dart';

/// Named route paths used throughout the app.
class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
}

/// Provider that exposes the [GoRouter] instance to the widget tree.
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Application router configuration using go_router.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.attendance,
        name: 'attendance',
        builder: (context, state) => const AttendancePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ),
  );
}
