import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Api_Services/police_api_service.dart';
import '../Api_Services/api_service.dart'; // For getUserProfile
import 'police_report_details.dart';

/// Enhanced Police Service Request Screen
/// Supports comprehensive crime reporting with media attachments,
/// anonymous reporting, location selection, and real-time tracking
class PoliceServiceRequestScreen extends StatefulWidget {
  const PoliceServiceRequestScreen({super.key});

  @override
  State<PoliceServiceRequestScreen> createState() =>
      _PoliceServiceRequestScreenState();
}

class _PoliceServiceRequestScreenState
    extends State<PoliceServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _useDifferentLocation = false;
  bool _isAnonymous = false;

  Map<String, dynamic>? _homeAddress;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  GoogleMapController? _mapController;
  File? _selectedMedia;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Load user profile and home address
  Future<void> _loadProfile() async {
    try {
      final profile = await getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _homeAddress = {
            'address': profile['address'] ?? 'No address set',
            'latitude': profile['latitude'] ?? 0.0,
            'longitude': profile['longitude'] ?? 0.0,
          };
          _addressController.text = _homeAddress!['address'];
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get current GPS location
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var status = await Permission.location.request();
      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _selectedLocation = _currentLocation;
          });

          // Move map camera to current location
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(_currentLocation!),
            );
          }

          // Update address field placeholder
          _addressController.text = 'Current Location (GPS)';
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle map tap to select location
  void _onMapTapped(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  /// Pick media file (photo/video evidence)
  Future<void> _pickMedia() async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Evidence Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final picked = await picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (picked != null && mounted) {
          setState(() {
            _selectedMedia = File(picked.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Submit police report with comprehensive validation
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate location selection
    LatLng? reportLocation;
    String address;

    if (_useDifferentLocation) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a location on the map'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      reportLocation = _selectedLocation!;
      address = _addressController.text.trim();

      if (address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide address or landmark information'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_homeAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home address not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      reportLocation = LatLng(
        _homeAddress!['latitude'],
        _homeAddress!['longitude'],
      );
      address = _homeAddress!['address'];
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await PoliceApiService.submitPoliceReport(
        description: _descriptionController.text.trim(),
        address: address,
        latitude: reportLocation.latitude,
        longitude: reportLocation.longitude,
        anonymous: _isAnonymous,
        media: _selectedMedia,
      );

      if (mounted) {
        // Navigate to tracking screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PoliceReportDetailsScreen(
              reportId: result.reportId.toString(),
              isAnonymous: result.anonymous,
              reportData: {
                'report_id': result.reportId,
                'description': _descriptionController.text.trim(),
                'address': address,
                if (reportLocation != null) ...{
                  'latitude': reportLocation.latitude,
                  'longitude': reportLocation.longitude,
                },
                'anonymous': result.anonymous,
                'status': 'pending',
                'assigned_station': result.assignedStation,
                'distance_km': result.distanceKm,
                'media_attached': result.mediaAttached,
                'operator_status': 'registered',
              },
            ),
          ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Crime'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),

              // Description
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incident Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Describe what happened in detail...',
                          border: OutlineInputBorder(),
                          helperText: 'Provide as much detail as possible',
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a description';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incident Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location Options
                      SwitchListTile(
                        title: const Text('Use different location'),
                        subtitle: Text(
                          _useDifferentLocation
                              ? 'Select location on map'
                              : 'Using home address',
                        ),
                        value: _useDifferentLocation,
                        onChanged: (value) {
                          setState(() {
                            _useDifferentLocation = value;
                            if (value && _selectedLocation == null) {
                              _getCurrentLocation();
                            }
                          });
                        },
                      ),

                      if (!_useDifferentLocation && _homeAddress != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Home Address:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(_homeAddress!['address']),
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${_homeAddress!['latitude']}, Lng: ${_homeAddress!['longitude']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_useDifferentLocation) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Use Current Location'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_selectedLocation != null) ...[
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GoogleMap(
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                              initialCameraPosition: CameraPosition(
                                target: _selectedLocation!,
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: _selectedLocation!,
                                  infoWindow: const InfoWindow(
                                    title: 'Incident Location',
                                  ),
                                ),
                              },
                              onTap: _onMapTapped,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address or Landmark',
                            hintText:
                                'Provide address, landmark, or directions...',
                            border: OutlineInputBorder(),
                          ),
                          validator: _useDifferentLocation
                              ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please provide address or landmark';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Evidence Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evidence (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickMedia,
                        icon: Icon(
                          _selectedMedia != null
                              ? Icons.check_circle
                              : Icons.camera_alt,
                        ),
                        label: Text(
                          _selectedMedia != null
                              ? 'Evidence Attached'
                              : 'Attach Photo/Video',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedMedia != null
                              ? Colors.green
                              : Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_selectedMedia != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedMedia!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Anonymous Option
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('Submit Anonymously'),
                        subtitle: const Text(
                          'Anonymous reports require operator verification '
                          'and may take longer to process',
                        ),
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value;
                          });
                        },
                      ),
                      if (_isAnonymous) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Anonymous reports take longer to process as '
                                  'they require operator verification before '
                                  'being assigned to police.',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.local_police),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Police Report',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
