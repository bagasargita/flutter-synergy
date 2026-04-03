import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/features/auth/auth_page.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/auth/auth_controller.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _WidgetTestAuthController extends AuthController {
  _WidgetTestAuthController()
    : super(_NoopAuthService(), restoreFromStorage: false) {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

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

  testWidgets('App renders login page on start', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _WidgetTestAuthController(),
          ),
        ],
        child: const MaterialApp(home: AuthPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
