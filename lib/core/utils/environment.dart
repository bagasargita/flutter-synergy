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
  factory Environment.dev() => const Environment(
        env: Env.dev,
        baseUrl: 'https://api-dev.example.com',
        enableLogging: true,
      );

  /// Production configuration.
  factory Environment.prod() => const Environment(
        env: Env.prod,
        baseUrl: 'https://api.example.com',
        enableLogging: false,
      );

  bool get isDev => env == Env.dev;
  bool get isProd => env == Env.prod;
}
