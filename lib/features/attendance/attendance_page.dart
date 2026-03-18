import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/core/theme/app_theme.dart';
import 'package:flutter_synergy/features/camera/camera_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Center of office geofence.
  static const LatLng _officeCenter = LatLng(-6.188099, 106.896144);

  // Rectangular geofence (~50m radius) around office center.
  static const List<LatLng> _geofencePolygon = <LatLng>[
    LatLng(-6.187699, 106.895744),
    LatLng(-6.188499, 106.895744),
    LatLng(-6.188499, 106.896544),
    LatLng(-6.187699, 106.896544),
  ];

  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isGettingLocation = false;
  String? _locationError;

  bool get _isInsideGeofence {
    if (_currentLocation == null) return false;
    const distance = Distance();
    final meters = distance(_currentLocation!, _officeCenter);
    return meters <= 50; // 50m radius around office
  }

  @override
  void initState() {
    super.initState();
    _refreshLocation();
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
        desiredAccuracy: LocationAccuracy.high,
      );

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

  Future<void> _openCamera() async {
    final String? photoPath = await Navigator.of(context).push<String?>(
      MaterialPageRoute<String?>(
        builder: (context) => const CameraPage(
          title: 'Check-in photo',
        ),
      ),
    );
    if (!mounted) return;
    if (photoPath != null && photoPath.isNotEmpty) {
      // TODO: Upload photo or save for check-in (e.g. send to API with location).
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo captured for check-in')),
      );
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
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
              // Map card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultRadius * 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultRadius * 1.2,
                    ),
                    child: Stack(
                      children: [
                        // OpenStreetMap map with polygon geofence and marker.
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: const MapOptions(
                              initialCenter: _officeCenter,
                              initialZoom: 18,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.flutter_synergy',
                              ),
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: _geofencePolygon,
                                    color: Colors.red.withValues(alpha: 0.3),
                                    borderStrokeWidth: 2,
                                    borderColor: Colors.red,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  // Office marker
                                  // Marker(
                                  //   point: _officeCenter,
                                  //   width: 40,
                                  //   height: 40,
                                  //   child: const Icon(
                                  //     Icons.my_location,
                                  //     color: Colors.blue,
                                  //     size: 32,
                                  //   ),
                                  // ),
                                  if (_currentLocation != null)
                                    Marker(
                                      point: _currentLocation!,
                                      width: 40,
                                      height: 40,
                                      child:
                                          // Container(
                                          // decoration: BoxDecoration(
                                          //   shape: BoxShape.circle,
                                          //   color: Colors.white,
                                          //   boxShadow: [
                                          //     BoxShadow(
                                          //       color: Colors.black.withValues(
                                          //         alpha: 0.25,
                                          //       ),
                                          //       blurRadius: 6,
                                          //       offset: const Offset(0, 2),
                                          //     ),
                                          //   ],
                                          // ),
                                          const Icon(
                                            Icons.person_pin_circle,
                                            color: Colors.green,
                                            size: 40,
                                          ),
                                      // ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Time chip
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
                              '08:23 AM',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Refresh position button
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 32,
                              left: 24,
                              right: 24,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  _refreshLocation();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.15,
                                  ),
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
                ),
              ),
              const SizedBox(height: 24),
              // Accuracy + message
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
                      Text(
                        _locationError ??
                            (_currentLocation != null
                                ? 'Location updated'
                                : 'Getting current location...'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentLocation == null
                        ? 'Unable to determine if you are inside the office area yet.'
                        : _isInsideGeofence
                        ? 'You are within the 50m geofence office area'
                        : 'You are outside the 50m geofence office area',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Check In button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _openCamera,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultRadius * 1.5,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Check In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
