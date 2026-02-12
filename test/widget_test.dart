import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/main.dart';

void main() {
  testWidgets('App renders login page on start', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FlutterSynergyApp()),
    );
    await tester.pumpAndSettle();

    // The login page should show the Sign In button.
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });
}
