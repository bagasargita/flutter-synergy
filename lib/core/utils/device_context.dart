import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Best-effort device id and local network IP for attendance multipart payloads.
class DeviceContext {
  DeviceContext._();

  static const _kInstallId = 'flutter_synergy_install_device_id';

  static Future<String> getOrCreateDeviceId() async {
    final p = await SharedPreferences.getInstance();
    var id = p.getString(_kInstallId);
    if (id == null || id.isEmpty) {
      id =
          '${Platform.operatingSystem}_${DateTime.now().microsecondsSinceEpoch}';
      await p.setString(_kInstallId, id);
    }
    return id;
  }

  /// First non-loopback IPv4, or empty string.
  static Future<String> bestEffortLocalIpv4() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '';
  }
}
