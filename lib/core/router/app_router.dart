import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/features/auth/auth_page.dart';
import 'package:flutter_synergy/features/auth/auth_controller.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_page.dart';
import 'package:flutter_synergy/features/attendance/attendance_page.dart';

/// Named route paths used throughout the app.
class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
}

/// [GoRouter] that redirects based on [AuthStatus] from [authControllerProvider].
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final isAuthenticated = status == AuthStatus.authenticated;
      final onLogin = state.matchedLocation == RoutePaths.login;

      if (!isAuthenticated) {
        if (onLogin) return null;
        return RoutePaths.login;
      }

      if (onLogin) return RoutePaths.dashboard;
      return null;
    },
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
});
