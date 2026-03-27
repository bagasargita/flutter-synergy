import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Describes available app environments.
enum Env { dev, prod }

/// Holds environment-specific configuration such as base URL and
/// feature flags.
///
/// An [Environment] instance is created once in `main.dart` and
/// provided to the rest of the app through Riverpod.
class Environment {
  final Env env;
  final String baseUrl;
  final bool enableLogging;

  const Environment({
    required this.env,
    required this.baseUrl,
    this.enableLogging = false,
  });

  /// Development configuration – points to mock / local server.
  factory Environment.dev() => Environment(
    env: Env.dev,
    baseUrl: dotenv.env['BASE_URL_DEV'] ?? dotenv.env['BASE_URL'] ?? 'https://api-dev.example.com',
    enableLogging: true,
  );

  /// Production configuration.
  factory Environment.prod() => Environment(
    env: Env.prod,
    baseUrl: dotenv.env['BASE_URL_PROD'] ??
        dotenv.env['BASE_URL'] ??
        'https://sbs.synergyengineering.com/api_mobile/',
    enableLogging: false,
  );

  bool get isDev => env == Env.dev;
  bool get isProd => env == Env.prod;
}
