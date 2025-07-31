import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';

class SetHomeAddressScreen extends StatefulWidget {
  const SetHomeAddressScreen({super.key});

  @override
  State<SetHomeAddressScreen> createState() => _SetHomeAddressScreenState();
}

class _SetHomeAddressScreenState extends State<SetHomeAddressScreen> {
  final TextEditingController fullAddressController = TextEditingController();
  LatLng? selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getInitialLocation();
    });
  }

  Future<void> _getInitialLocation() async {
    setState(() => _isLoading = true);

    try {
      var status = await Permission.location.status;
      if (status.isDenied ||
          status.isRestricted ||
          status.isPermanentlyDenied) {
        status = await Permission.location.request();
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        setState(() => _isLoading = false);
        return;
      }

      final saved = await getHomeAddress();

      if (saved != null &&
          saved['latitude'] != null &&
          saved['longitude'] != null) {
        selectedLocation = LatLng(
          double.parse(saved['latitude'].toString()),
          double.parse(saved['longitude'].toString()),
        );
        fullAddressController.text = saved['address'] ?? '';
      } else {
        Position position = await Geolocator.getCurrentPosition();
        selectedLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      print('Location fetch error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveHomeAddress() async {
    if (selectedLocation == null || fullAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    try {
      await setHomeAddress(
        address: fullAddressController.text,
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Home address saved successfully!")),
      );
    } catch (e) {
      print('Save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save home address")),
      );
    }
  }

  void _onMapTapped(LatLng latLng) {
    setState(() {
      selectedLocation = latLng;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Set Home Address",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shadowColor: Colors.grey,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: fullAddressController,
                    decoration: InputDecoration(
                      labelText: "Full Address",
                      hintText: "House 10, Road 5, Banani, Dhaka",
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 250, 240, 255),
                    ),
                    maxLines: 2,
                  ),
                ),
                if (selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      "Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Tap on the map to select your home address",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
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
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "Save Home Address",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveHomeAddress,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
