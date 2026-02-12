import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/core/utils/token_storage.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';

/// The possible states for the authentication flow.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Immutable state object for the auth feature.
class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier that drives the auth UI.
///
/// Keeps the [AuthState] and exposes [login] / [logout] actions.
/// Easily unit-testable by injecting a mock [AuthService].
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthState());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      // Persist token for future requests.
      await TokenStorage.saveToken(user.token);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );

      AppLogger.info('Login successful for ${user.email}');
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      AppLogger.error('Login failed', error: e);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await TokenStorage.clearToken();

    state = const AuthState(status: AuthStatus.unauthenticated);
    AppLogger.info('User logged out');
  }
}
