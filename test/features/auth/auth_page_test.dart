import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/features/auth/auth_controller.dart';
import 'package:flutter_synergy/features/auth/auth_page.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopAuthService implements AuthService {
  @override
  Future<CurrentUserProfile> fetchCurrentUser() async {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

class TestAuthController extends AuthController {
  TestAuthController(AuthState initial)
    : super(_NoopAuthService(), restoreFromStorage: false) {
    state = initial;
  }

  String? lastUsername;
  String? lastPassword;
  bool loginCalled = false;

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    loginCalled = true;
    lastUsername = username;
    lastPassword = password;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pkgChannel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pkgChannel, (call) async {
          if (call.method == 'getAll') {
            return <String, dynamic>{
              'appName': 'Flutter Synergy',
              'packageName': 'com.synergy.flutter_synergy',
              'version': '1.0.0',
              'buildNumber': '1',
              'buildSignature': '',
            };
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pkgChannel, null);
  });

  Future<void> _pump(
    WidgetTester tester, {
    required TestAuthController controller,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: AuthPage()),
      ),
    );
    await tester.pump();
  }

  group('AuthPage', () {
    testWidgets('renders login UI', (tester) async {
      final controller = TestAuthController(
        const AuthState(status: AuthStatus.unauthenticated),
      );
      await _pump(tester, controller: controller);

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows validation and blocks submit for empty inputs', (
      tester,
    ) async {
      final controller = TestAuthController(
        const AuthState(status: AuthStatus.unauthenticated),
      );
      await _pump(tester, controller: controller);

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(controller.loginCalled, isFalse);
    });

    testWidgets('submits username/password when form is valid', (tester) async {
      final controller = TestAuthController(
        const AuthState(status: AuthStatus.unauthenticated),
      );
      await _pump(tester, controller: controller);

      await tester.enterText(find.byType(TextFormField).at(0), 'john.doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(controller.loginCalled, isTrue);
      expect(controller.lastUsername, 'john.doe');
      expect(controller.lastPassword, 'secret123');
    });
  });
}
