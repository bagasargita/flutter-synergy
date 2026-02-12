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
    controller = AuthController(mockService);
  });

  group('AuthController', () {
    test('initial state is AuthStatus.initial', () {
      expect(controller.state.status, AuthStatus.initial);
      expect(controller.state.user, isNull);
      expect(controller.state.errorMessage, isNull);
    });

    test('login sets loading then authenticated on success', () async {
      const mockUser = AuthUser(
        id: 'usr_001',
        name: 'Test User',
        email: 'test@example.com',
        token: 'token_abc',
      );

      when(() => mockService.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockUser);

      final states = <AuthState>[];
      controller.addListener(states.add);

      await controller.login(email: 'test@example.com', password: 'pass123');

      // Should have gone through loading -> authenticated.
      expect(states.any((s) => s.status == AuthStatus.loading), isTrue);
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user?.email, 'test@example.com');
    });

    test('login sets error state on failure', () async {
      when(() => mockService.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('Invalid credentials'));

      await controller.login(email: 'bad@email.com', password: 'wrong');

      expect(controller.state.status, AuthStatus.error);
      expect(controller.state.errorMessage, isNotNull);
    });

    test('logout resets to unauthenticated', () async {
      when(() => mockService.logout()).thenAnswer((_) async {});

      await controller.logout();

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.user, isNull);
    });
  });
}
