import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_synergy/features/auth/auth_controller.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';

// --- Mocks ---

class MockAuthService extends Mock implements AuthService {}

void main() {
  // Required for SharedPreferences in TokenStorage.
  WidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockService;
  late AuthController controller;

  setUp(() {
    // Provide an empty SharedPreferences for each test.
    SharedPreferences.setMockInitialValues({});

    mockService = MockAuthService();
    controller = AuthController(mockService, restoreFromStorage: false);
  });

  group('AuthController', () {
    test('initial state is AuthStatus.initial when restore disabled', () {
      expect(controller.state.status, AuthStatus.initial);
      expect(controller.state.user, isNull);
      expect(controller.state.profile, isNull);
      expect(controller.state.errorMessage, isNull);
    });

    test('login sets loading then authenticated on success', () async {
      const mockUser = AuthUser(
        id: 'usr_001',
        name: 'Test User',
        username: 'test@example.com',
        accessToken: 'token_abc',
        accessExpiresAt: '2026-03-27T14:26:34.296+07:00',
        refreshToken: 'refresh_abc',
        refreshExpiresAt: '2026-04-26T14:11:34.297+07:00',
      );

      when(
        () => mockService.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockUser);

      const mockProfile = CurrentUserProfile(
        fullName: 'Mobile Developer',
        companyName: 'SE',
        disciplineName: 'IT',
        titleName: 'IT System Developer',
        checkInAnywhere: true,
        workPlaces: [],
        selfieRequired: true,
      );
      when(
        () => mockService.fetchCurrentUser(),
      ).thenAnswer((_) async => mockProfile);

      final states = <AuthState>[];
      controller.addListener(states.add);

      await controller.login(username: 'test@example.com', password: 'pass123');

      // Should have gone through loading -> authenticated.
      expect(states.any((s) => s.status == AuthStatus.loading), isTrue);
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user?.username, 'test@example.com');
    });

    test('login sets error state on failure', () async {
      when(
        () => mockService.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('Invalid credentials'));

      await controller.login(username: 'bad@email.com', password: 'wrong');

      expect(controller.state.status, AuthStatus.error);
      expect(controller.state.errorMessage, isNotNull);
    });

    test('logout resets to unauthenticated', () async {
      when(() => mockService.logout()).thenAnswer((_) async {});

      await controller.logout();

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.user, isNull);
      expect(controller.state.profile, isNull);
    });
  });
}
