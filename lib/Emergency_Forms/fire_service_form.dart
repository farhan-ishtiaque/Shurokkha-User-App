import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FireEmergencyForm extends StatefulWidget {
  @override
  _FireEmergencyFormState createState() => _FireEmergencyFormState();
}

enum LocationOption { gps, manual }

class _FireEmergencyFormState extends State<FireEmergencyForm> {
  final _formKey = GlobalKey<FormState>();

  // Address fields
  String flatNumber = '';
  String houseNumber = '';
  String roadNumber = '';
  String area = '';
  String city = '';
  String incidentType = 'Fire';
  String description = '';
  DateTime timestamp = DateTime.now();

  // Location
  LocationOption _locationOption = LocationOption.gps;
  String gpsLocation = '';
  String manualLatitude = '';
  String manualLongitude = '';

  final List<String> incidentTypes = [
    'Fire',
    'Gas Leak',
    'Chemical Hazard',
    'Building Collapse',
    'Rescue Needed',
    'Other',
  ];

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      gpsLocation = '${position.latitude}, ${position.longitude}';
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      timestamp = DateTime.now();

      // Choose correct location
      if (_locationOption == LocationOption.manual) {
        gpsLocation = '$manualLatitude, $manualLongitude';
      }

      print('--- Emergency Request Submitted ---');
      print('Flat: $flatNumber');
      print('House: $houseNumber');
      print('Road: $roadNumber');
      print('Area: $area');
      print('City: $city');
      print('Incident: $incidentType');
      print('Location: $gpsLocation');
      print('Description: $description');
      print('Timestamp: $timestamp');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency request submitted successfully!')),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Fire Request'),
        centerTitle: true,
        backgroundColor: Colors.red.shade600,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Flat Number',
                    onSaved: (val) => flatNumber = val!,
                    validator: (val) =>
                        val!.isEmpty ? 'Flat number is required' : null,
                  ),
                  _buildTextField(
                    label: 'House Number',
                    onSaved: (val) => houseNumber = val!,
                    validator: (val) =>
                        val!.isEmpty ? 'House number is required' : null,
                  ),
                  _buildTextField(
                    label: 'Road Number',
                    onSaved: (val) => roadNumber = val!,
                    validator: (val) =>
                        val!.isEmpty ? 'Road number is required' : null,
                  ),
                  _buildTextField(
                    label: 'Area',
                    onSaved: (val) => area = val!,
                    validator: (val) =>
                        val!.isEmpty ? 'Area is required' : null,
                  ),
                  _buildTextField(
                    label: 'City',
                    onSaved: (val) => city = val!,
                    validator: (val) => val!.isEmpty ? 'City is required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: incidentType,
                    decoration: InputDecoration(
                      labelText: 'Incident Type',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: incidentTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => incidentType = val!),
                    onSaved: (val) => incidentType = val!,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: 'Description (Optional)',
                    onSaved: (val) => description = val ?? '',
                    maxLines: 4,
                  ),

                  // Location Option Selector
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Location Option:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ListTile(
                    title: const Text('Use current GPS location'),
                    leading: Radio<LocationOption>(
                      value: LocationOption.gps,
                      groupValue: _locationOption,
                      onChanged: (LocationOption? value) {
                        setState(() {
                          _locationOption = value!;
                          gpsLocation = '';
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Enter location manually'),
                    leading: Radio<LocationOption>(
                      value: LocationOption.manual,
                      groupValue: _locationOption,
                      onChanged: (LocationOption? value) {
                        setState(() {
                          _locationOption = value!;
                        });
                      },
                    ),
                  ),

                  if (_locationOption == LocationOption.gps) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            gpsLocation.isEmpty
                                ? 'No location selected.'
                                : 'Location: $gpsLocation',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.my_location),
                          color: Colors.red.shade600,
                          tooltip: 'Get Location',
                          onPressed: _getLocation,
                        ),
                      ],
                    ),
                  ],

                  if (_locationOption == LocationOption.manual) ...[
                    _buildTextField(
                      label: 'Latitude',
                      onSaved: (val) => manualLatitude = val!,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter latitude' : null,
                      keyboardType: TextInputType.number,
                    ),
                    _buildTextField(
                      label: 'Longitude',
                      onSaved: (val) => manualLongitude = val!,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter longitude'
                          : null,
                      keyboardType: TextInputType.number,
                    ),
                  ],

                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: Icon(Icons.fire_truck),
                    label: Text('Submit Emergency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
