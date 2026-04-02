import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/core/router/app_router.dart';
import 'package:flutter_synergy/core/theme/app_theme.dart';
import 'package:flutter_synergy/core/utils/environment.dart';
import 'package:flutter_synergy/core/utils/global_error_handler.dart';
import 'package:flutter_synergy/core/api/api_provider.dart';
import 'package:flutter_synergy/core/widgets/root_scaffold_messenger_key.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/app_env');

  // Select environment based on build flavour / compile-time flag.
  // Change to Environment.prod() for production builds.
  final environment = Environment.dev();

  GlobalErrorHandler.init(() async {
    runApp(
      ProviderScope(
        overrides: [
          // Inject the chosen environment into the Riverpod graph.
          environmentProvider.overrideWithValue(environment),
        ],
        child: const FlutterSynergyApp(),
      ),
    );
  });
}

class FlutterSynergyApp extends ConsumerWidget {
  const FlutterSynergyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // Anti–fake-GPS: Android MethodChannel `com.attendance.security/check`
      // (SecurityService + MainActivity / SecurityChecker.kt).
      scaffoldMessengerKey: globalScaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
