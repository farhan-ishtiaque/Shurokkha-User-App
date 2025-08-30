import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EnhancedAddressPicker extends StatefulWidget {
  final Function(String address, double lat, double lng) onAddressChanged;
  final TextEditingController addressController;

  const EnhancedAddressPicker({
    super.key,
    required this.onAddressChanged,
    required this.addressController,
  });

  @override
  State<EnhancedAddressPicker> createState() => _EnhancedAddressPickerState();
}

class _EnhancedAddressPickerState extends State<EnhancedAddressPicker> {
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        throw Exception("Location permission not granted");
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('⚠️ Getting current position failed, trying last known: $e');
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null) {
        setState(() {
          _latitude = pos!.latitude;
          _longitude = pos.longitude;
        });
      } else {
        // fallback to Dhaka
        setState(() {
          _latitude = 23.7806;
          _longitude = 90.4006;
        });
      }

      widget.onAddressChanged(
        widget.addressController.text,
        _latitude!,
        _longitude!,
      );
    } catch (e) {
      debugPrint('⚠️ Location fallback: $e');
      setState(() {
        _latitude = 23.7806;
        _longitude = 90.4006;
      });

      widget.onAddressChanged(
        widget.addressController.text,
        _latitude!,
        _longitude!,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "Tap on the map to select your exact location",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 16),

        // Google Map (always visible)
        if (_latitude != null && _longitude != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(_latitude!, _longitude!),
                zoom: 15,
              ),
              onTap: (LatLng position) {
                // Allow user to select location by tapping on map
                setState(() {
                  _latitude = position.latitude;
                  _longitude = position.longitude;
                });

                // Update the parent widget with new coordinates
                widget.onAddressChanged(
                  widget.addressController.text,
                  _latitude!,
                  _longitude!,
                );
              },
              markers: {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: LatLng(_latitude!, _longitude!),
                  infoWindow: const InfoWindow(
                    title: 'Selected Location',
                    snippet: 'Tap anywhere on map to change',
                  ),
                ),
              },
              // Optimize map for performance and fix rendering issues
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              tiltGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              mapType: MapType.normal,
              buildingsEnabled: false,
              trafficEnabled: false,
              indoorViewEnabled: false,
              liteModeEnabled: false,
            ),
          ),

        const SizedBox(height: 16),

        // Location coordinates and refresh button
        Row(
          children: [
            Expanded(
              child: Text(
                "Lat: ${_latitude?.toStringAsFixed(6) ?? 'Loading...'}\n"
                "Lng: ${_longitude?.toStringAsFixed(6) ?? 'Loading...'}",
                style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text("Present Location"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
