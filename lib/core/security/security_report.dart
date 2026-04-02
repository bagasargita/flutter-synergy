import 'dart:convert';

/// Result of a pre–clock-in security sweep (mock GPS, root, motion heuristics, etc.).
class SecurityReport {
  const SecurityReport({
    required this.isMockLocation,
    required this.isDeveloperMode,
    required this.isRooted,
    required this.isEmulator,
    required this.isSuspiciousMovement,
  });

  /// Combined mock signal (native last fix + Geolocator + platform hints).
  final bool isMockLocation;

  /// Android: Settings / developer options enabled (heuristic).
  final bool isDeveloperMode;

  /// Rooted / jailbroken-style environment (Android native).
  final bool isRooted;

  /// Likely emulator (Android native heuristics).
  final bool isEmulator;

  /// Impossible movement / teleport vs sensor stillness.
  final bool isSuspiciousMovement;

  /// Block clock-in / clock-out when any hard signal trips.
  bool get isRisky =>
      isMockLocation ||
      isDeveloperMode ||
      isRooted ||
      isEmulator ||
      isSuspiciousMovement;

  Map<String, dynamic> toJson() => {
        'isMockLocation': isMockLocation,
        'isDeveloperMode': isDeveloperMode,
        'isRooted': isRooted,
        'isEmulator': isEmulator,
        'isSuspiciousMovement': isSuspiciousMovement,
      };

  String toJsonString() => jsonEncode(toJson());
}

/// GPS sample captured when security checks pass (sent with attendance payload).
class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.isMockedFromGeolocator,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy in meters (negative if unknown).
  final double accuracy;

  /// Speed in m/s (may be NaN / negative if unavailable).
  final double speed;

  /// From Geolocator / platform (Android `Location.isMock`).
  final bool isMockedFromGeolocator;

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'isMockedFromGeolocator': isMockedFromGeolocator,
      };
}
