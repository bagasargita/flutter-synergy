import 'package:flutter/widgets.dart';
import 'package:flutter_synergy/core/utils/token_storage.dart';
import 'package:flutter_synergy/features/auth/auth_controller.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late AuthController controller;

  const user = AuthUser(
    id: 'u-1',
    name: 'John',
    username: 'john.doe',
    accessToken: 'access-token',
    accessExpiresAt: '2026-04-03T08:00:00+07:00',
    refreshToken: 'refresh-token',
    refreshExpiresAt: '2026-05-03T08:00:00+07:00',
  );

  const profile = CurrentUserProfile(
    fullName: 'John Doe',
    companyName: 'SE',
    disciplineName: 'IT',
    titleName: 'Engineer',
    checkInAnywhere: true,
    workPlaces: <WorkPlace>[],
    selfieRequired: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    authService = MockAuthService();
    controller = AuthController(authService, restoreFromStorage: false);
  });

  test('login -> restoreSession -> logout journey is deterministic', () async {
    // Arrange
    when(
      () => authService.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);
    when(() => authService.fetchCurrentUser()).thenAnswer((_) async => profile);
    when(() => authService.logout()).thenAnswer((_) async {});

    // Act
    await controller.login(username: 'john.doe', password: 'secret123');
    final storedTokenAfterLogin = await TokenStorage.getToken();

    final restored = AuthController(authService, restoreFromStorage: false);
    await restored.restoreSession();

    await restored.logout();
    final storedTokenAfterLogout = await TokenStorage.getToken();

    // Assert
    expect(controller.state.status, AuthStatus.authenticated);
    expect(storedTokenAfterLogin, 'access-token');

    expect(restored.state.status, AuthStatus.unauthenticated);
    expect(storedTokenAfterLogout, isNull);
  });
}
