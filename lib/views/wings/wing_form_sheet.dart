import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_event.dart';
import '../../models/wing_model.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/pms_ui.dart';

class WingFormSheet extends StatefulWidget {
  final WingModel? wing;

  const WingFormSheet({super.key, this.wing});

  static Future<void> show(BuildContext context, {WingModel? wing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PmsTheme.glassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<WingBloc>(),
        child: WingFormSheet(wing: wing),
      ),
    );
  }

  @override
  State<WingFormSheet> createState() => _WingFormSheetState();
}

class _WingFormSheetState extends State<WingFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _locationController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;
  late final TextEditingController _searchController;

  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  double _radiusMeters = 200.0;
  bool _isDetectingGps = false;
  bool _isSearching = false;
  String? _mapStatus;

  static const LatLng _defaultCenter = LatLng(27.6094, 75.1398); // Sikar, Rajasthan center

  @override
  void initState() {
    super.initState();
    final w = widget.wing;
    _nameController = TextEditingController(text: w?.name ?? '');
    _codeController = TextEditingController(text: w?.code ?? '');
    _locationController = TextEditingController(text: w?.location ?? '');

    if (w != null && w.latitude != null && w.longitude != null) {
      _selectedLatLng = LatLng(w.latitude!, w.longitude!);
      _latController = TextEditingController(text: w.latitude!.toStringAsFixed(6));
      _lngController = TextEditingController(text: w.longitude!.toStringAsFixed(6));
      _mapStatus = 'Pin: ${w.latitude!.toStringAsFixed(4)}, ${w.longitude!.toStringAsFixed(4)}';
    } else {
      _latController = TextEditingController();
      _lngController = TextEditingController();
      _selectedLatLng = _defaultCenter;
    }

    _radiusMeters = (w?.geofenceRadiusMeters ?? 200).toDouble().clamp(50.0, 5000.0);
    _radiusController = TextEditingController(text: _radiusMeters.round().toString());
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateCoordinates(double lat, double lng, {bool animateMap = false, double? zoom}) {
    final newPos = LatLng(
      double.parse(lat.toStringAsFixed(6)),
      double.parse(lng.toStringAsFixed(6)),
    );
    setState(() {
      _selectedLatLng = newPos;
      _latController.text = newPos.latitude.toStringAsFixed(6);
      _lngController.text = newPos.longitude.toStringAsFixed(6);
      _mapStatus = 'Pin: ${newPos.latitude.toStringAsFixed(4)}, ${newPos.longitude.toStringAsFixed(4)}';
    });

    if (animateMap && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, zoom ?? 16.0),
      );
    }
  }

  void _onLatOrLngInputChanged() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
      _updateCoordinates(lat, lng, animateMap: true);
    }
  }

  void _updateRadius(double meters) {
    final clamped = meters.clamp(50.0, 5000.0);
    setState(() {
      _radiusMeters = clamped;
      _radiusController.text = clamped.round().toString();
    });
  }

  Future<void> _detectGpsLocation() async {
    setState(() => _isDetectingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showPmsSnackBar(context, 'Please enable GPS / Location service on your device.', kind: PmsSnackKind.warning);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showPmsSnackBar(context, 'Location permission denied.', kind: PmsSnackKind.error);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showPmsSnackBar(context, 'Location permission is permanently denied. Enable in app settings.', kind: PmsSnackKind.error);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _updateCoordinates(pos.latitude, pos.longitude, animateMap: true, zoom: 16.5);
      if (mounted) {
        showPmsSnackBar(
          context,
          '📍 GPS detected: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
          kind: PmsSnackKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showPmsSnackBar(context, 'Could not detect GPS location: $e', kind: PmsSnackKind.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingGps = false);
      }
    }
  }

  Future<void> _searchLocationOnMap() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _mapStatus = 'Searching map...';
    });

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {'User-Agent': 'PMSApp/1.0 (admin-wing-geofence)'},
        ),
      );

      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'format': 'json', 'q': query, 'limit': 1},
      );

      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        final first = (response.data as List).first as Map<String, dynamic>;
        final lat = double.tryParse(first['lat'].toString());
        final lon = double.tryParse(first['lon'].toString());

        if (lat != null && lon != null) {
          final displayName = first['display_name']?.toString() ?? query;
          final shortName = displayName.split(',').first;
          _updateCoordinates(lat, lon, animateMap: true, zoom: 16.0);
          setState(() {
            _mapStatus = 'Found: $shortName';
          });
          if (mounted) {
            showPmsSnackBar(context, '📍 Found: $shortName', kind: PmsSnackKind.success);
          }
          return;
        }
      }

      setState(() => _mapStatus = 'Location not found');
      if (mounted) {
        showPmsSnackBar(context, 'Location not found. Try searching with city/locality name (e.g. Sikar).', kind: PmsSnackKind.warning);
      }
    } catch (e) {
      setState(() => _mapStatus = 'Search failed');
      if (mounted) {
        showPmsSnackBar(context, 'Error searching location: $e', kind: PmsSnackKind.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final location = _locationController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = int.tryParse(_radiusController.text.trim()) ?? _radiusMeters.round();

    final payload = <String, dynamic>{
      'name': name,
      'code': code.isNotEmpty ? code : null,
      'location': location.isNotEmpty ? location : null,
      'latitude': lat,
      'longitude': lng,
      'geofence_radius_meters': radius,
    };

    if (widget.wing != null) {
      context.read<WingBloc>().add(
        UpdateWingEvent(wingId: widget.wing!.id, payload: payload),
      );
    } else {
      context.read<WingBloc>().add(CreateWingEvent(payload));
    }

    Navigator.pop(context);
    showPmsSnackBar(
      context,
      widget.wing != null ? '✓ Wing updated successfully!' : '✓ Wing created successfully!',
      kind: PmsSnackKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.wing != null;
    final pinPos = _selectedLatLng ?? _defaultCenter;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PmsSheetHeader(
                title: isEditing ? 'Edit Institute Wing' : 'Add Institute Wing',
                subtitle: isEditing
                    ? 'Update wing profile, GPS coordinates & geofence radius'
                    : 'Register a campus with work-start geofence boundary',
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 14),

              // Wing Name
              _buildFieldLabel('Wing / Campus Name *'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PmsTheme.textPrimary),
                decoration: _inputDecoration('e.g. Prince Academy (CBSE), PCP Sikar'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter Wing / Campus name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Wing Code & Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Wing Code'),
                        TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PmsTheme.textPrimary),
                          decoration: _inputDecoration('PA-01, PCP-01'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Campus Location'),
                        TextFormField(
                          controller: _locationController,
                          style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
                          decoration: _inputDecoration('Palwas Road, Sikar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ================= GEOFENCE & MAP PICKER SECTION =================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section Header with Auto-detect button
                    Row(
                      children: [
                        const Icon(Icons.share_location_rounded, color: PmsTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Geofence Boundary & Map Picker',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: PmsTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Work Start Verification Boundary',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: PmsTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _isDetectingGps ? null : _detectGpsLocation,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isDetectingGps)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: PmsTheme.primary),
                                  )
                                else
                                  const Icon(Icons.my_location_rounded, size: 14, color: PmsTheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  _isDetectingGps ? 'Detecting...' : 'Auto-GPS',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: PmsTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Map Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 12, color: PmsTheme.textPrimary),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchLocationOnMap(),
                              decoration: InputDecoration(
                                hintText: 'Search landmark/address (e.g. Sikar)...',
                                hintStyle: const TextStyle(color: PmsTheme.textMuted, fontSize: 11),
                                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: PmsTheme.textMuted),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: PmsTheme.primary, width: 1.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _searchLocationOnMap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _isSearching
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Search', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Interactive Google Map
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: pinPos,
                              zoom: widget.wing?.latitude != null ? 16.0 : 13.5,
                            ),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            compassEnabled: true,
                            gestureRecognizers: {
                              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                            },
                            onMapCreated: (ctrl) {
                              _mapController = ctrl;
                            },
                            onTap: (latLng) {
                              _updateCoordinates(latLng.latitude, latLng.longitude);
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('wing_boundary_center'),
                                position: pinPos,
                                draggable: true,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                                infoWindow: InfoWindow(
                                  title: _nameController.text.isNotEmpty ? _nameController.text : 'Wing Center',
                                  snippet: 'Geofence Radius: ${_radiusMeters.round()}m',
                                ),
                                onDragEnd: (newPos) {
                                  _updateCoordinates(newPos.latitude, newPos.longitude);
                                },
                              ),
                            },
                            circles: {
                              Circle(
                                circleId: const CircleId('wing_geofence_boundary'),
                                center: pinPos,
                                radius: _radiusMeters,
                                fillColor: const Color(0x336366F1), // Translucent indigo
                                strokeColor: const Color(0xFF4F46E5), // Solid indigo
                                strokeWidth: 2,
                              ),
                            },
                          ),

                          // Top-right map reset / center button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.white,
                              elevation: 2,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(pinPos, 16.0),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.center_focus_strong_rounded, size: 18, color: PmsTheme.primary),
                                ),
                              ),
                            ),
                          ),

                          // Bottom Status & Hint Chip
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.touch_app_rounded, size: 14, color: PmsTheme.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _mapStatus ?? 'Tap map or drag pin to position center',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_radiusMeters.round()}m',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: PmsTheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Latitude, Longitude and Radius Boundary Inputs
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Latitude'),
                              TextFormField(
                                controller: _latController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                decoration: _inputDecoration('27.6100'),
                                onChanged: (_) => _onLatOrLngInputChanged(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Longitude'),
                              TextFormField(
                                controller: _lngController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                decoration: _inputDecoration('75.1400'),
                                onChanged: (_) => _onLatOrLngInputChanged(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildFieldLabel('Radius'),
                                  Text(
                                    '${_radiusMeters.round()}m',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: PmsTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              TextFormField(
                                controller: _radiusController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PmsTheme.primary),
                                decoration: _inputDecoration('200', suffix: 'm'),
                                onChanged: (val) {
                                  final numVal = double.tryParse(val.trim());
                                  if (numVal != null && numVal >= 50) {
                                    setState(() {
                                      _radiusMeters = numVal.clamp(50.0, 5000.0);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Slider for Radius
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Geofence Radius Slider',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: PmsTheme.textSecondary),
                            ),
                            Text(
                              '${_radiusMeters.round()} meters',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PmsTheme.primary),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: PmsTheme.primary,
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            thumbColor: PmsTheme.primary,
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          ),
                          child: Slider(
                            value: _radiusMeters.clamp(50.0, 2000.0),
                            min: 50.0,
                            max: 2000.0,
                            divisions: 195,
                            onChanged: (val) => _updateRadius(val),
                          ),
                        ),
                      ],
                    ),

                    const Text(
                      'Digital Studio crew members can only mark shoot work as started when their mobile device GPS is within this radius circle.',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B), // Amber matching Admin Save Wing button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Save Wing',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: PmsTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PmsTheme.primary, width: 1.5),
      ),
    );
  }
}
