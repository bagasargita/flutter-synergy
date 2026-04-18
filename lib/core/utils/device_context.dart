import 'dart:io';
import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Best-effort device id and local network IP for attendance multipart payloads.
class DeviceContext {
  DeviceContext._();

  static const _kInstallId = 'flutter_synergy_install_device_id';
  static const _secure = FlutterSecureStorage();
  static const _androidId = AndroidId();

  static Future<String> getOrCreateDeviceId() async {
    // 1) Prefer secure storage (persists better across app restarts/hot reload).
    final secureId = await _secure.read(key: _kInstallId);
    if (secureId != null && secureId.isNotEmpty) {
      return secureId;
    }

    // 2) Backward compatibility: migrate existing SharedPreferences value.
    final p = await SharedPreferences.getInstance();
    final prefsId = p.getString(_kInstallId);
    if (prefsId != null && prefsId.isNotEmpty) {
      await _secure.write(key: _kInstallId, value: prefsId);
      return prefsId;
    }

    // 3) First install: create once, then persist in both stores.
    final id = await _buildStableDeviceId();
    await _secure.write(key: _kInstallId, value: id);
    await p.setString(_kInstallId, id);
    return id;
  }

  static Future<String> _buildStableDeviceId() async {
    try {
      if (Platform.isAndroid) {
        // Prefer SSAID for Android; usually stable across reinstall for the
        // same app signing key + user profile.
        final aid = (await _androidId.getId())?.trim() ?? '';
        if (aid.isNotEmpty) {
          return 'android_${_fnv1a64Hex('android|$aid')}';
        }
      }

      final plugin = DeviceInfoPlugin();
      final os = Platform.operatingSystem;
      late final Map<String, dynamic> data;

      if (Platform.isAndroid) {
        data = (await plugin.androidInfo).data;
      } else if (Platform.isIOS) {
        data = (await plugin.iosInfo).data;
      } else if (Platform.isWindows) {
        data = (await plugin.windowsInfo).data;
      } else if (Platform.isMacOS) {
        data = (await plugin.macOsInfo).data;
      } else if (Platform.isLinux) {
        data = (await plugin.linuxInfo).data;
      } else {
        data = <String, dynamic>{};
      }

      final seed = _stableSeedFromData(data, os: os);
      if (seed.isNotEmpty) {
        return '${os}_${_fnv1a64Hex(seed)}';
      }
    } catch (_) {
      // fallback below
    }

    // Last resort (still persisted): not as strong as hardware-backed IDs.
    return '${Platform.operatingSystem}_${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _stableSeedFromData(
    Map<String, dynamic> data, {
    required String os,
  }) {
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty && s.toLowerCase() != 'unknown' && s != 'null') {
          return s;
        }
      }
      return '';
    }

    final parts = <String>[
      os,
      pick(const ['identifierForVendor']),
      pick(const ['androidId']),
      pick(const ['id']),
      pick(const ['machineId']),
      pick(const ['systemGUID']),
      pick(const ['biosSerial']),
      pick(const ['device', 'model', 'brand']),
      pick(const ['name', 'hostName', 'computerName']),
    ]..removeWhere((e) => e.isEmpty);

    return parts.join('|');
  }

  static String _fnv1a64Hex(String input) {
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    var hash = fnvOffset;
    for (final b in utf8.encode(input)) {
      hash ^= b;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
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

  /// Best-effort human-readable device name for attendance payload.
  static Future<String> bestEffortDeviceName() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        final name = [brand, model].where((e) => e.isNotEmpty).join(' - ');
        if (name.isNotEmpty) return name;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final name = info.name.trim();
        if (name.isNotEmpty) return name;
        final model = info.model.trim();
        if (model.isNotEmpty) return model;
      } else if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        final name = info.computerName.trim();
        if (name.isNotEmpty) return name;
      } else if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        final name = info.computerName.trim();
        if (name.isNotEmpty) return name;
      } else if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        final name = info.name.trim();
        if (name.isNotEmpty) return name;
      }
    } catch (_) {
      // fallback below
    }
    return Platform.operatingSystem;
  }
}
