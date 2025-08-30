import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';

class FireServiceRequestScreen extends StatefulWidget {
  const FireServiceRequestScreen({super.key});

  @override
  State<FireServiceRequestScreen> createState() =>
      _FireServiceRequestScreenState();
}

class _FireServiceRequestScreenState extends State<FireServiceRequestScreen> {
  bool isLoading = true;
  bool useDifferentLocation = false;
  Map<String, dynamic>? homeAddress;
  LatLng? selectedLocation;
  GoogleMapController? _mapController;

  final TextEditingController descriptionController = TextEditingController();
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

  void _submitRequest() async {
    final description = descriptionController.text.trim();
    final additionalInfo = additionalInfoController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Description is required")));
      return;
    }

    final LatLng location = useDifferentLocation
        ? selectedLocation!
        : LatLng(homeAddress!['latitude'], homeAddress!['longitude']);

    final String address = useDifferentLocation
        ? additionalInfo
        : homeAddress!['address'];

    final bool success = await submitFireReport(
      description: description,
      address: address,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fire report submitted successfully")),
      );
      Navigator.pop(context); // Or navigate to confirmation screen
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to submit report")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fire Service Request"),
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
              "Incident Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: "Describe the fire emergency or required service...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                onPressed: _submitRequest,
                icon: const Icon(Icons.local_fire_department),
                label: const Text("Submit Fire Report"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
