import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/api/api_provider.dart';
import 'package:flutter_synergy/features/auth/auth_controller.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';

/// Provides [AuthService] – the API layer for authentication.
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

/// Provides [AuthController] – the state layer for authentication.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authService = ref.watch(authServiceProvider);
    return AuthController(authService);
  },
);
