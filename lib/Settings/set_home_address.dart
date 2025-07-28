import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SetHomeAddressScreen extends StatefulWidget {
  const SetHomeAddressScreen({super.key});

  @override
  State<SetHomeAddressScreen> createState() => _SetHomeAddressScreenState();
}

class _SetHomeAddressScreenState extends State<SetHomeAddressScreen> {
  final TextEditingController fullAddressController = TextEditingController();
  LatLng? selectedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getInitialLocation();
  }

  Future<void> _getInitialLocation() async {
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

  Future<void> _saveHomeAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null ||
        selectedLocation == null ||
        fullAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("https://your-django-url/api/set-home-address/"),
      headers: {'Authorization': 'Token $token'},
      body: {
        'full_address': fullAddressController.text,
        'latitude': selectedLocation!.latitude.toString(),
        'longitude': selectedLocation!.longitude.toString(),
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Home address saved successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save home address.")),
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
      body: Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}",
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
                        onMapCreated: (controller) => _mapController = controller,
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
                  label: const Text("Save Home Address",
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  print("Token: $token");
  print("Address: ${fullAddressController.text}");
  print("LatLng: $selectedLocation");

  _saveHomeAddress();
},

                  

                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
