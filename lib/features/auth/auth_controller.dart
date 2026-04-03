import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:flutter_synergy/core/utils/token_storage.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';

/// The possible states for the authentication flow.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Immutable state object for the auth feature.
class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final CurrentUserProfile? profile;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    CurrentUserProfile? profile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
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
  final bool restoreFromStorage;

  AuthController(this._authService, {this.restoreFromStorage = true})
    : super(const AuthState()) {
    if (restoreFromStorage) {
      restoreSession();
    }
  }

  /// Rebuilds [AuthState] from [TokenStorage] after hot restart / process death.
  Future<void> restoreSession() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final refreshToken = await TokenStorage.getRefreshToken() ?? '';
    final accessExpiresAt = await TokenStorage.getAccessExpiresAt() ?? '';
    final refreshExpiresAt = await TokenStorage.getRefreshExpiresAt() ?? '';
    final username = await TokenStorage.getSavedUsername() ?? '';
    final profile = CurrentUserProfile.tryParseStorageJson(
      await TokenStorage.getUserProfileJson(),
    );
    final name = (profile?.fullName.isNotEmpty == true)
        ? profile!.fullName
        : username;

    state = AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(
        id: '',
        name: name,
        username: username,
        accessToken: token,
        accessExpiresAt: accessExpiresAt,
        refreshToken: refreshToken,
        refreshExpiresAt: refreshExpiresAt,
      ),
      profile: profile,
    );
    AppLogger.info('Session restored from storage');
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final user = await _authService.login(
        username: username,
        password: password,
      );

      // Persist access/refresh tokens with their expiration metadata.
      await TokenStorage.saveAuthSession(
        accessToken: user.accessToken,
        accessExpiresAt: user.accessExpiresAt,
        refreshToken: user.refreshToken,
        refreshExpiresAt: user.refreshExpiresAt,
      );

      try {
        final profile = await _authService.fetchCurrentUser();
        await TokenStorage.saveUserProfileJson(profile.toStorageJsonString());
        await TokenStorage.saveUsername(user.username);

        final displayName = profile.fullName.isNotEmpty
            ? profile.fullName
            : user.name;

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user.copyWith(name: displayName),
          profile: profile,
        );

        AppLogger.info('Login successful for ${user.username}');
      } catch (e) {
        final message = e is ApiException ? e.message : e.toString();
        await TokenStorage.clearToken();
        state = state.copyWith(status: AuthStatus.error, errorMessage: message);
        AppLogger.error('Failed to load user profile after login', error: e);
      }
    } catch (e) {
      final message = e is ApiException ? e.message : e.toString();
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
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
