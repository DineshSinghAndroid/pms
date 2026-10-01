import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/pms_theme.dart';

class HoardingMapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const HoardingMapPickerDialog({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<HoardingMapPickerDialog> createState() => _HoardingMapPickerDialogState();
}

class _HoardingMapPickerDialogState extends State<HoardingMapPickerDialog> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isDetecting = false;

  static const LatLng _defaultCenter = LatLng(27.6094, 75.1398); // Sikar / Rajasthan center default

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _selectedLocation = _defaultCenter;
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetecting = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable GPS / Location service.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is permanently denied. Enable in Settings.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selectedLocation = newLoc;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLoc, 16.5),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location detected: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
            duration: const Duration(seconds: 2),
            backgroundColor: PmsTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not detect location: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedLocation ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pick Site Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedLocation);
            },
            child: const Text(
              'DONE',
              style: TextStyle(
                color: PmsTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: widget.initialLat != null ? 15 : 8,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (ctrl) {
              _mapController = ctrl;
            },
            onTap: (latLng) {
              setState(() {
                _selectedLocation = latLng;
              });
            },
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('picked_site'),
                      position: _selectedLocation!,
                      draggable: true,
                      onDragEnd: (newPos) {
                        setState(() {
                          _selectedLocation = newPos;
                        });
                      },
                    ),
                  }
                : {},
          ),
          // Coordinates info card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: PmsTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedLocation != null
                          ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                          : 'Tap map or use Current Location button',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Detect Current Location Button (Floating action button)
          Positioned(
            bottom: 84,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'detect_current_loc_btn',
              elevation: 4,
              backgroundColor: Colors.white,
              foregroundColor: PmsTheme.primary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                side: BorderSide(color: Color(0xFFCBD5E1), width: 1),
              ),
              onPressed: _isDetecting ? null : _detectCurrentLocation,
              icon: _isDetecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: PmsTheme.primary),
                    )
                  : const Icon(Icons.my_location_rounded, color: PmsTheme.primary, size: 20),
              label: Text(
                _isDetecting ? 'Detecting...' : 'Current Location',
                style: const TextStyle(
                  color: PmsTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          // Confirm Location Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PmsTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: const Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
