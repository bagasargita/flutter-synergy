import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:flutter_synergy/core/security/security_report.dart';

/// Channel name must match [MainActivity] / [SecurityChecker] on Android.
const String kSecurityMethodChannel = 'com.attendance.security/check';

/// User-facing copy when attendance is blocked (banner + submit `ApiException`).
const String kAttendanceLocationBlockedMessage =
    'Location not trusted. Please disable Fake GPS or use a trusted location.';

/// Max distance (meters) considered a “teleport” if it happens within [_teleportWindow].
const double _teleportDistanceMeters = 1000;

/// Time window (seconds) for teleport detection.
const int _teleportWindowSeconds = 10;

/// Speed threshold (km/h) from GPS — above this is suspicious.
const double _maxCredulitySpeedKmh = 200;

/// If user accelerometer magnitude stays below this (m/s²) during sampling while a
/// teleport is suspected, we treat the device as physically still (spoof risk).
const double _stillUserAccelThreshold = 0.28;

/// Sample length for user accelerometer (excludes gravity).
const Duration _accelSampleDuration = Duration(milliseconds: 450);

/// Production-oriented anti–fake-GPS helper: native Android signals + motion heuristics.
///
/// **Limits:** No client-only check is perfect. Combine with server-side validation,
/// Wi‑Fi/BSSID, and anomaly detection. iOS native checks are not implemented; methods
/// return non-risky defaults on non-Android.
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  static const MethodChannel _channel = MethodChannel(kSecurityMethodChannel);

  final _motion = _LocationMotionTracker();
  LocationSnapshot? _lastAcceptedSnapshot;

  /// Last GPS sample that passed [checkSecurity] (for attendance POST).
  LocationSnapshot? get lastAcceptedSnapshot => _lastAcceptedSnapshot;

  /// Call on each map “refresh position” so teleport heuristics have a baseline.
  void recordPositionSample(Position position) => _motion.record(position);

  /// True if the OS / Geolocator reports a mock location.
  Future<bool> isFakeGPS() async {
    final r = await checkSecurity();
    return r.isMockLocation;
  }

  Future<bool> isDeveloperMode() => _nativeBool('isDeveloperMode');

  Future<bool> isRooted() => _nativeBool('isRooted');

  /// Aggregated report + optional motion / speed checks (Flutter layer).
  Future<SecurityReport> checkSecurity() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return const SecurityReport(
        isMockLocation: false,
        isDeveloperMode: false,
        isRooted: false,
        isEmulator: false,
        isSuspiciousMovement: true,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );

    final results = await Future.wait<bool>([
      _nativeBool('isMockLocation'),
      _nativeBool('isDeveloperMode'),
      _nativeBool('isRooted'),
      _nativeBool('isEmulator'),
    ]);

    final nativeMock = results[0];
    final devMode = results[1];
    final rooted = results[2];
    final emulator = results[3];

    final geoMock = position.isMocked;
    final mockCombined = nativeMock || geoMock;

    final teleport = _motion.evaluateTeleport(position);
    _motion.record(position);

    var suspiciousMovement = false;

    final speedKmh = position.speed >= 0 && !position.speed.isNaN
        ? position.speed * 3.6
        : 0.0;
    if (speedKmh > _maxCredulitySpeedKmh) {
      suspiciousMovement = true;
    }

    if (teleport) {
      final peakAccel = await _peakUserAccelerometerMagnitude();
      if (peakAccel < _stillUserAccelThreshold) {
        suspiciousMovement = true;
      }
    }

    final report = SecurityReport(
      isMockLocation: mockCombined,
      isDeveloperMode: devMode,
      isRooted: rooted,
      isEmulator: emulator,
      isSuspiciousMovement: suspiciousMovement,
    );

    if (!report.isRisky) {
      _lastAcceptedSnapshot = LocationSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        isMockedFromGeolocator: position.isMocked,
      );
    } else {
      _lastAcceptedSnapshot = null;
    }

    return report;
  }

  Future<bool> _nativeBool(String method) async {
    if (!Platform.isAndroid) return false;
    try {
      final v = await _channel.invokeMethod<bool>(method);
      return v ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Peak magnitude of user acceleration (linear, gravity removed) over a short window.
  Future<double> _peakUserAccelerometerMagnitude() async {
    try {
      var peak = 0.0;
      final sub = userAccelerometerEventStream().listen((e) {
        final m = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (m > peak) peak = m;
      });
      await Future<void>.delayed(_accelSampleDuration);
      await sub.cancel();
      return peak;
    } catch (_) {
      return 999;
    }
  }
}

/// Tracks last fix to detect impossible jumps (spoof apps jumping map pin).
class _LocationMotionTracker {
  Position? _last;
  DateTime? _lastTime;

  void record(Position p) {
    _last = p;
    _lastTime = DateTime.now();
  }

  /// > [_teleportDistanceMeters] within [_teleportWindowSeconds] seconds.
  bool evaluateTeleport(Position current) {
    final last = _last;
    final t = _lastTime;
    if (last == null || t == null) return false;

    final dt = DateTime.now().difference(t);
    if (dt.inSeconds >= _teleportWindowSeconds) return false;

    final d = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      current.latitude,
      current.longitude,
    );
    return d > _teleportDistanceMeters;
  }
}
