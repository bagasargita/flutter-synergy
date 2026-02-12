/// Application-wide constants.
///
/// Keep magic numbers and strings here so they are easy to find
/// and update in one place.
class AppConstants {
  AppConstants._();

  // -- Networking --
  static const int connectTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds

  // -- Pagination --
  static const int defaultPageSize = 20;

  // -- UI --
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;

  // -- App Info --
  static const String appName = 'Flutter Synergy';
  static const String appVersion = '1.0.0';
}
