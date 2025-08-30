import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';

class MedicalServiceRequestScreen extends StatefulWidget {
  const MedicalServiceRequestScreen({super.key});

  @override
  State<MedicalServiceRequestScreen> createState() =>
      _MedicalServiceRequestScreenState();
}

class _MedicalServiceRequestScreenState
    extends State<MedicalServiceRequestScreen> {
  bool isLoading = true;
  bool useDifferentLocation = false;
  bool _isSubmitting = false;

  Map<String, dynamic>? homeAddress;
  LatLng? selectedLocation;
  GoogleMapController? _mapController;

  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController additionalInfoController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await getUserProfile();
    if (profile != null) {
      setState(() {
        homeAddress = {
          'address': profile['address'] ?? 'No address set',
          'latitude': profile['latitude'] ?? 0.0,
          'longitude': profile['longitude'] ?? 0.0,
        };
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load user profile")),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
    }
  }

  void _onMapTapped(LatLng latLng) {
    setState(() {
      selectedLocation = latLng;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  // Submit emergency medical report
  Future<void> _submitEmergencyReport() async {
    final symptoms = symptomsController.text.trim();

    if (symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your symptoms')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Position position;
      String address = '';

      if (useDifferentLocation && selectedLocation != null) {
        // Use selected location
        position = Position(
          latitude: selectedLocation!.latitude,
          longitude: selectedLocation!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        address = additionalInfoController.text.trim().isEmpty
            ? 'Custom location'
            : additionalInfoController.text.trim();
      } else {
        // Use home address
        if (homeAddress != null) {
          position = Position(
            latitude: homeAddress!['latitude'].toDouble(),
            longitude: homeAddress!['longitude'].toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          address = homeAddress!['address'];
        } else {
          throw Exception('No location available');
        }
      }

      // Submit medical report using enhanced API service with report_id return
      final result = await submitMedicalEmergencyReport(
        description: symptoms,
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (result['success'] == true) {
        final reportId = result['report_id'];
        final category = result['category'];

        print('✅ Medical report submitted with ID: $reportId');
        print('📊 Category: $category');

        // Show success message with more details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              category == 'ordinary'
                  ? 'Emergency report submitted! AI advice provided.'
                  : 'Emergency report submitted! Hospitals have been notified.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to home page after successful submission
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception(result['error'] ?? 'Failed to submit medical report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Emergency Request"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.grey,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe Your Symptoms",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: symptomsController,
              decoration: const InputDecoration(
                hintText:
                    "e.g., Severe chest pain, difficulty breathing, dizziness...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text("Use Different Location?"),
                Switch(
                  value: useDifferentLocation,
                  onChanged: (val) {
                    setState(() {
                      useDifferentLocation = val;
                      if (val && selectedLocation == null) {
                        _getCurrentLocation();
                      }
                    });
                  },
                ),
              ],
            ),
            if (!useDifferentLocation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Using Home Address:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(homeAddress!['address']),
                  Text(
                    "Lat: ${homeAddress!['latitude']}, Lng: ${homeAddress!['longitude']}",
                  ),
                ],
              ),
            if (useDifferentLocation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Set Location on Map",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: selectedLocation == null
                        ? const Center(child: CircularProgressIndicator())
                        : GoogleMap(
                            onMapCreated: (controller) =>
                                _mapController = controller,
                            initialCameraPosition: CameraPosition(
                              target: selectedLocation!,
                              zoom: 16,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("selected_location"),
                                position: selectedLocation!,
                              ),
                            },
                            onTap: _onMapTapped,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                          ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Additional Location Info"),
                  TextField(
                    controller: additionalInfoController,
                    decoration: const InputDecoration(
                      hintText: "Landmark or extra directions...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitEmergencyReport,
                icon: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.emergency),
                label: Text(
                  _isSubmitting ? "Submitting..." : "Submit Emergency Report",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Help Text
            Text(
              'Your location will be automatically detected. Make sure you have enabled location permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
