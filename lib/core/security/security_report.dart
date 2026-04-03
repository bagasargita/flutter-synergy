import 'dart:convert';

/// Result of a pre–clock-in security sweep (mock GPS, root, motion heuristics, etc.).
class SecurityReport {
  const SecurityReport({
    this.permissionDenied = false,
    required this.isMockLocation,
    required this.isDeveloperMode,
    required this.isRooted,
    required this.isEmulator,
    required this.isSuspiciousMovement,
  });

  /// Location permission denied — cannot obtain a trustworthy fix.
  final bool permissionDenied;

  /// Combined mock signal (native last fix + Geolocator + platform hints).
  final bool isMockLocation;

  /// Android: Settings / developer options enabled (heuristic).
  ///
  /// **Not** part of [isRisky] — many users keep Developer options on. Still in [toJson].
  final bool isDeveloperMode;

  /// Rooted / jailbroken-style environment (Android native).
  final bool isRooted;

  /// Likely emulator (Android native heuristics).
  final bool isEmulator;

  /// Impossible movement / teleport vs sensor stillness.
  final bool isSuspiciousMovement;

  /// Block clock-in / clock-out when a **security** signal trips.
  ///
  /// Excludes [isDeveloperMode] (see field doc). Use [toJson] for full telemetry.
  bool get isRisky =>
      permissionDenied ||
      isMockLocation ||
      isRooted ||
      isEmulator ||
      isSuspiciousMovement;

  Map<String, dynamic> toJson() => {
    'permissionDenied': permissionDenied,
    'isMockLocation': isMockLocation,
    'isDeveloperMode': isDeveloperMode,
    'isRooted': isRooted,
    'isEmulator': isEmulator,
    'isSuspiciousMovement': isSuspiciousMovement,
  };

  String toJsonString() => jsonEncode(toJson());
}

/// [ApiException.data] key when submit was blocked by [SecurityReport.isRisky].
const String kAttendanceSecurityBlockDataKey = 'attendance_security_block';

/// User-visible explanation for the **first** failing check (priority order).
String attendanceSecurityBlockMessage(SecurityReport r) {
  if (r.permissionDenied) {
    return 'Location permission is required. Allow location access in Settings, then try again.';
  }
  if (r.isMockLocation) {
    return 'Mock or simulated location is still reported. Turn off Fake GPS, clear mock location app as mock provider, restart the phone if needed, then refresh on the map.';
  }
  if (r.isEmulator) {
    return 'This device appears to be an emulator. Use a physical phone for attendance.';
  }
  if (r.isRooted) {
    return 'This device appears to be rooted. Contact IT if this is an approved work phone.';
  }
  if (r.isSuspiciousMovement) {
    return 'GPS looked unstable (large jump or speed spike). Stay still, wait ~15s, tap Refresh on the map, then try again.';
  }
  return 'Location could not be verified. Try again or contact IT.';
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
