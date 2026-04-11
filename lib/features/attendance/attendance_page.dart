import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/core/security/security_report.dart';
import 'package:flutter_synergy/core/security/security_service.dart';
import 'package:flutter_synergy/core/theme/app_theme.dart';
import 'package:flutter_synergy/core/widgets/global_top_banner.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';
import 'package:flutter_synergy/features/attendance/attendance_models.dart';
import 'package:flutter_synergy/features/attendance/attendance_processing_page.dart';
import 'package:flutter_synergy/features/camera/camera_page.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key, this.kind = AttendanceSubmitKind.checkIn});

  final AttendanceSubmitKind kind;

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isGettingLocation = false;
  String? _locationError;
  Timer? _clockTimer;

  bool _profileLoading = true;
  String? _profileError;
  CurrentUserProfile? _profile;
  List<List<LatLng>> _geofencePolygons = [];

  /// Local time for the chip, e.g. `08:23 AM`.
  static String _formatTimeNow() {
    final t = DateTime.now();
    var h = t.hour;
    final m = t.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    final mm = m.toString().padLeft(2, '0');
    final hh = h.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  /// `lat;lng;lat;lng;...` from `/users/me` work_places.
  static List<LatLng>? _parseCoordinateString(String raw) {
    final parts = raw
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length < 6 || parts.length % 2 != 0) return null;
    final list = <LatLng>[];
    for (var i = 0; i < parts.length; i += 2) {
      final lat = double.tryParse(parts[i]);
      final lng = double.tryParse(parts[i + 1]);
      if (lat == null || lng == null) return null;
      list.add(LatLng(lat, lng));
    }
    if (list.length < 3) return null;
    return list;
  }

  static List<List<LatLng>> _polygonsFromWorkPlaces(List<WorkPlace> places) {
    final out = <List<LatLng>>[];
    for (final wp in places) {
      final pts = _parseCoordinateString(wp.coordinates);
      if (pts != null) {
        out.add(pts);
      }
    }
    return out;
  }

  static LatLng _centroid(List<LatLng> ring) {
    if (ring.isEmpty) return const LatLng(-6.2, 106.8);
    double sLat = 0, sLng = 0;
    for (final p in ring) {
      sLat += p.latitude;
      sLng += p.longitude;
    }
    final n = ring.length;
    return LatLng(sLat / n, sLng / n);
  }

  /// Ray casting (lng = x, lat = y) — fine for small office geofences.
  static bool _pointInPolygon(LatLng point, List<LatLng> ring) {
    if (ring.length < 3) return false;
    final x = point.longitude;
    final y = point.latitude;
    var inside = false;
    var j = ring.length - 1;
    for (var i = 0; i < ring.length; j = i++) {
      final xi = ring[i].longitude;
      final yi = ring[i].latitude;
      final xj = ring[j].longitude;
      final yj = ring[j].latitude;
      final intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  LatLng get _mapInitialCenter {
    if (_geofencePolygons.isNotEmpty) {
      return _centroid(_geofencePolygons.first);
    }
    return const LatLng(-6.2, 106.8);
  }

  /// True when current GPS is inside any workplace polygon (ignores `check_in_anywhere`).
  bool get _isInsideAnyWorkplacePolygon {
    if (_currentLocation == null) return false;
    if (_geofencePolygons.isEmpty) return false;
    for (final poly in _geofencePolygons) {
      if (_pointInPolygon(_currentLocation!, poly)) return true;
    }
    return false;
  }

  bool get _canCheckIn {
    if (_profileLoading || _profile == null) return false;
    if (_profile!.checkInAnywhere) return true;
    if (_geofencePolygons.isEmpty) return false;
    return _isInsideAnyWorkplacePolygon;
  }

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadProfileThenLocation();
  }

  Future<void> _loadProfileThenLocation() async {
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final profile = await ref.read(authServiceProvider).fetchCurrentUser();
      if (!mounted) return;
      final polygons = _polygonsFromWorkPlaces(profile.workPlaces);
      setState(() {
        _profile = profile;
        _geofencePolygons = polygons;
        _profileLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (polygons.isNotEmpty) {
          _mapController.move(_centroid(polygons.first), 17);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileError = e.toString();
          _profileLoading = false;
        });
      }
    }
    await _refreshLocation();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      SecurityService.instance.recordPositionSample(position);

      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = currentLatLng;
      });

      _mapController.move(currentLatLng, 18);
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _onCheckInOutPressed() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location is required. Refresh position first.'),
        ),
      );
      return;
    }

    final profile = _profile;
    if (profile == null) return;

    // TODO: Uncomment this after testing
    final report = await SecurityService.instance.checkSecurity();
    if (!mounted) return;
    if (report.isRisky) {
      GlobalTopBanner.showError(
        title: 'Attendance blocked',
        subtitle: attendanceSecurityBlockMessage(report),
      );
      return;
    }

    if (!profile.selfieRequired) {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => AttendanceProcessingPage(kind: widget.kind),
        ),
      );
      return;
    }

    await _openCamera();
  }

  Future<void> _openCamera() async {
    final title = widget.kind == AttendanceSubmitKind.checkIn
        ? 'Check-in photo'
        : 'Check-out photo';

    final String? photoPath = await Navigator.of(context).push<String?>(
      MaterialPageRoute<String?>(
        builder: (context) => CameraPage(title: title),
      ),
    );
    if (!mounted) return;
    if (photoPath == null || photoPath.isEmpty) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            AttendanceProcessingPage(kind: widget.kind, photoPath: photoPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.kind == AttendanceSubmitKind.checkIn
              ? 'Check In'
              : 'Check Out',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Expanded(
                child: _profileLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _profileError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _profileError!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadProfileThenLocation,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildMapCard(theme),
              ),
              const SizedBox(height: 24),
              if (!_profileLoading && _profileError == null) ...[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _locationError ??
                                (_isGettingLocation
                                    ? 'Getting current location...'
                                    : (_currentLocation != null
                                          ? 'Location updated'
                                          : 'Location unavailable')),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _geofenceStatusMessage(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canCheckIn ? _onCheckInOutPressed : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius * 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.kind == AttendanceSubmitKind.checkIn
                          ? 'Check In'
                          : 'Check Out',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _geofenceStatusMessage() {
    final p = _profile;
    if (p == null) {
      return 'Loading profile…';
    }
    if (p.checkInAnywhere) {
      return 'Check-in is allowed from anywhere for your account.';
    }
    if (_geofencePolygons.isEmpty) {
      return 'No workplace geofence is configured. Contact HR.';
    }
    if (_currentLocation == null) {
      return 'Unable to determine if you are inside a workplace area yet.';
    }
    if (_isInsideAnyWorkplacePolygon) {
      return 'You are inside a configured workplace area.';
    }
    return 'You are outside all configured workplace areas.';
  }

  Widget _buildMapCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius * 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius * 1.2),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapInitialCenter,
                  initialZoom: 17,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_synergy',
                  ),
                  if (_geofencePolygons.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        for (var i = 0; i < _geofencePolygons.length; i++)
                          Polygon(
                            points: _geofencePolygons[i],
                            color: Colors.red.withValues(alpha: 0.25),
                            borderStrokeWidth: 2,
                            borderColor: Colors.red,
                          ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _formatTimeNow(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _refreshLocation,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('REFRESH POSITION'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
