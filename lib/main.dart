import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/core/router/app_router.dart';
import 'package:flutter_synergy/core/theme/app_theme.dart';
import 'package:flutter_synergy/core/utils/environment.dart';
import 'package:flutter_synergy/core/utils/global_error_handler.dart';
import 'package:flutter_synergy/core/api/api_provider.dart';

Future<void> main() async {
  // Select environment based on build flavour / compile-time flag.
  // Change to Environment.prod() for production builds.
  final environment = Environment.dev();

  GlobalErrorHandler.init(() async {
    WidgetsFlutterBinding.ensureInitialized();

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
