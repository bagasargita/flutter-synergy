import 'package:flutter_synergy/core/security/security_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityReport', () {
    test('isRisky is true when a blocking signal is true', () {
      const report = SecurityReport(
        isMockLocation: false,
        isDeveloperMode: true,
        isRooted: false,
        isEmulator: false,
        isSuspiciousMovement: true,
      );

      expect(report.isRisky, isTrue);
    });

    test('isRisky ignores developer options alone', () {
      const report = SecurityReport(
        isMockLocation: false,
        isDeveloperMode: true,
        isRooted: false,
        isEmulator: false,
        isSuspiciousMovement: false,
      );

      expect(report.isRisky, isFalse);
    });

    test('toJson exposes all flags', () {
      const report = SecurityReport(
        isMockLocation: true,
        isDeveloperMode: true,
        isRooted: false,
        isEmulator: true,
        isSuspiciousMovement: false,
      );

      final json = report.toJson();

      expect(json['permissionDenied'], isFalse);
      expect(json['isMockLocation'], isTrue);
      expect(json['isDeveloperMode'], isTrue);
      expect(json['isRooted'], isFalse);
      expect(json['isEmulator'], isTrue);
      expect(json['isSuspiciousMovement'], isFalse);
    });
  });

  group('LocationSnapshot', () {
    test('toJson exposes coordinate and sensor data', () {
      const snap = LocationSnapshot(
        latitude: -6.2,
        longitude: 106.8,
        accuracy: 5.5,
        speed: 1.2,
        isMockedFromGeolocator: false,
      );

      final json = snap.toJson();

      expect(json['lat'], -6.2);
      expect(json['lng'], 106.8);
      expect(json['accuracy'], 5.5);
      expect(json['speed'], 1.2);
      expect(json['isMockedFromGeolocator'], isFalse);
    });
  });
}
