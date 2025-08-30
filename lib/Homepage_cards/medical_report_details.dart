import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Medical Report Details Screen with Live Driver Tracking
/// Shows real-time driver location and AI medical advice
class MedicalReportDetailsScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> reportData;

  const MedicalReportDetailsScreen({
    super.key,
    required this.documentId,
    required this.reportData,
  });

  @override
  State<MedicalReportDetailsScreen> createState() =>
      _MedicalReportDetailsScreenState();
}

class _MedicalReportDetailsScreenState
    extends State<MedicalReportDetailsScreen> {
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  StreamSubscription<DocumentSnapshot>? _medicalDriverSubscription;
  Map<String, dynamic>? _liveReportData;
  Timer? _refreshTimer;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _liveReportData = widget.reportData;
    _startLiveTracking();

    // Listen to assigned medical driver document for live location
    final driverId = widget.reportData['assigned_driver_id']?.toString();
    print('[DEBUG:initState] assigned_driver_id: $driverId');
    if (driverId != null) {
      _medicalDriverSubscription = FirebaseFirestore.instance
          .collection('medical_drivers')
          .doc(driverId)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
            print(
              '[DEBUG:medicalDriverSubscription] snapshot.exists: ${snapshot.exists}',
            );
            if (snapshot.exists) {
              final driverData = snapshot.data() as Map<String, dynamic>;
              print(
                '[DEBUG:medicalDriverSubscription] driverData: $driverData',
              );
              setState(() {
                // Store latest driver location in _liveReportData for marker update
                _liveReportData = {
                  ..._liveReportData!,
                  'medical_driver_location': driverData,
                };
              });
              _updateMapMarkers();
            }
          });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapMarkers();
    });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _medicalDriverSubscription?.cancel();
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Start live tracking for the medical report
  void _startLiveTracking() {
    print(
      '🚑 Starting live medical tracking for document: ${widget.documentId}',
    );

    // Listen to real-time updates from Firestore
    _driverLocationSubscription = FirebaseFirestore.instance
        .collection('medical_reports')
        .doc(widget.documentId)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
            if (snapshot.exists) {
              print('📍 Medical report data updated');
              setState(() {
                _liveReportData = snapshot.data() as Map<String, dynamic>;
              });
              _updateMapMarkers();
            }
          },
          onError: (error) {
            print('❌ Error listening to medical report updates: $error');
          },
        );

    // Set up periodic refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print('⏰ Timer refresh - checking for medical updates...');
      // The real-time listener handles updates, this is just for backup
    });
  }

  /// Update markers on the map with enhanced positioning
  void _updateMapMarkers() {
    final data = _liveReportData!;
    print('[DEBUG:_updateMapMarkers] _liveReportData: $data');
    final userLat = data['latitude'] is double
        ? data['latitude']
        : double.tryParse(data['latitude'].toString());
    final userLng = data['longitude'] is double
        ? data['longitude']
        : double.tryParse(data['longitude'].toString());
    print('[DEBUG:_updateMapMarkers] userLat: $userLat, userLng: $userLng');
    Set<Marker> newMarkers = {};

    // Add user marker
    if (userLat != null && userLng != null) {
      print(
        '[DEBUG:_updateMapMarkers] Adding user marker at ($userLat, $userLng)',
      );
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLat, userLng),
          infoWindow: const InfoWindow(
            title: '🏥 Emergency Location',
            snippet: 'Medical emergency reported here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Add medical driver marker from medical_drivers
    final medicalDriver =
        data['medical_driver_location'] as Map<String, dynamic>?;
    print('[DEBUG:_updateMapMarkers] medicalDriver: $medicalDriver');
    if (medicalDriver != null) {
      final fetchedLat = medicalDriver['latitude'] is double
          ? medicalDriver['latitude']
          : double.tryParse(medicalDriver['latitude'].toString());
      final fetchedLng = medicalDriver['longitude'] is double
          ? medicalDriver['longitude']
          : double.tryParse(medicalDriver['longitude'].toString());
      print(
        '[DEBUG:_updateMapMarkers] fetchedLat: $fetchedLat, fetchedLng: $fetchedLng',
      );
      if (fetchedLat != null && fetchedLng != null) {
        print(
          '[DEBUG:_updateMapMarkers] Adding driver marker at ($fetchedLat, $fetchedLng)',
        );
        newMarkers.add(
          Marker(
            markerId: const MarkerId('driver_location'),
            position: LatLng(fetchedLat, fetchedLng),
            infoWindow: InfoWindow(
              title: '🚑 Ambulance',
              snippet:
                  medicalDriver['driver_name'] ??
                  medicalDriver['name'] ??
                  'Driver',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }

    print('[DEBUG:_updateMapMarkers] newMarkers: $newMarkers');
    setState(() {
      _markers = newMarkers;
    });
    if (_mapController != null && newMarkers.isNotEmpty) {
      print('[DEBUG:_updateMapMarkers] Fitting markers in view');
      _fitMarkersInView();
    }
    // Only use new marker logic above. Old references removed.
  }

  /// Fit all markers in the map view
  void _fitMarkersInView() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      minLat = marker.position.latitude < minLat
          ? marker.position.latitude
          : minLat;
      maxLat = marker.position.latitude > maxLat
          ? marker.position.latitude
          : maxLat;
      minLng = marker.position.longitude < minLng
          ? marker.position.longitude
          : minLng;
      maxLng = marker.position.longitude > maxLng
          ? marker.position.longitude
          : maxLng;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.001, minLng - 0.001),
          northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
        ),
        100.0, // padding
      ),
    );
  }

  /// Call ambulance driver
  void _callDriver(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      try {
        await launchUrl(launchUri);
      } catch (e) {
        print('Could not launch $launchUri');
      }
    }
  }

  /// Call hospital
  void _callHospital(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      try {
        await launchUrl(launchUri);
      } catch (e) {
        print('Could not launch $launchUri');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_liveReportData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medical Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _liveReportData!;
    final description = data['description'] ?? 'No description provided';
    final location = data['address'] ?? 'Location not specified';
    final status = data['status'] ?? 'pending';
    final category = data['category'] ?? 'unknown';
    final aiAdvice = data['ai_advice'] ?? '';

    // Driver information from assigned_driver map and individual fields
  final assignedDriver = data['assigned_driver'] as Map<String, dynamic>?;
  final medicalDriver = data['medical_driver_location'] as Map<String, dynamic>?;
  final driverName =
    medicalDriver?['driver_name'] ??
    medicalDriver?['name'] ??
    assignedDriver?['name'] ??
    data['assigned_driver_name'] ??
    'Not assigned';
  final driverPhone =
    medicalDriver?['phone_number'] ??
    medicalDriver?['phone'] ??
    assignedDriver?['phone_number'] ??
    assignedDriver?['phone'] ??
    data['assigned_driver_phone'] ??
    data['driver_phone'] ??
    '';
    final driverStatus = assignedDriver != null
        ? (assignedDriver['status'] ?? 'unknown')
        : (data['assigned_driver_status'] ?? 'unknown');
    final assignedHospital =
        data['assigned_hospital_name'] ??
        data['assignedHospitalName'] ??
        'No hospital assigned';
    final hospitalPhone =
        data['assigned_hospital_phone'] ?? data['hospital_phone'] ?? '';

    // Driver marker logic is now handled entirely within _updateMapMarkers

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              _updateMapMarkers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map view with driver and user location markers
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _updateMapMarkers();
                  },
                  markers: _markers,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      (data['latitude'] is double
                              ? data['latitude']
                              : double.tryParse(data['latitude'].toString())) ??
                          23.8103,
                      (data['longitude'] is double
                              ? data['longitude']
                              : double.tryParse(
                                  data['longitude'].toString(),
                                )) ??
                          90.4125,
                    ),
                    zoom: 14.0,
                  ),
                  mapType: MapType.normal,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                  indoorViewEnabled: false,
                  liteModeEnabled: false,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'zoom_in',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                        child: const Icon(Icons.zoom_in, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'zoom_out',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                        child: const Icon(Icons.zoom_out, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Category Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          title: 'Status',
                          value: status.toUpperCase(),
                          color: _getStatusColor(status),
                          icon: _getStatusIcon(status),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatusCard(
                          title: 'Category',
                          value: category.toUpperCase(),
                          color: _getCategoryColor(category),
                          icon: _getCategoryIcon(category),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AI Medical Advice Card
                  if (aiAdvice.isNotEmpty) ...[
                    Card(
                      color: Colors.blue[50],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: Colors.blue[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'AI Medical Advice',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Text(
                                aiAdvice,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Driver Information Card
                  if (status == 'accepted' &&
                      (assignedDriver != null ||
                          data['assigned_driver_name'] != null ||
                          driverName != 'Not assigned')) ...[
                    Card(
                      color: Colors.green[50],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_hospital,
                                    color: Colors.green[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Ambulance Assigned',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                if (driverStatus.toLowerCase() != 'unknown')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: driverStatus == 'on-duty'
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      driverStatus.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Driver Info Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Driver: $driverName',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Hospital: $assignedHospital',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (driverPhone.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Contact: $driverPhone',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (driverPhone.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () => _callDriver(driverPhone),
                                    icon: const Icon(Icons.call, size: 18),
                                    label: const Text('Call'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if ((status == 'accepted' || status == 'assigned') &&
                      assignedDriver == null &&
                      data['assigned_driver_name'] == null &&
                      driverName == 'Not assigned') ...[
                    // Show hospital info and driver assignment status
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.blue.shade50,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_hospital,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hospital Assigned',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ACCEPTED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Hospital Info
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    assignedHospital,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (hospitalPhone.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _callHospital(hospitalPhone),
                                    icon: const Icon(Icons.call, size: 16),
                                    label: const Text('Call Hospital'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Driver assignment status
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Hospital is assigning ambulance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Report Details
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _DetailRow(
                            icon: Icons.description,
                            label: 'Symptoms',
                            value: description,
                          ),

                          _DetailRow(
                            icon: Icons.location_on,
                            label: 'Location',
                            value: location,
                          ),

                          _DetailRow(
                            icon: Icons.access_time,
                            label: 'Reported',
                            value: _formatTimestamp(data['timestamp']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets and Methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'serious':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'ordinary':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'accepted':
        return Icons.local_hospital;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'serious':
        return Icons.warning;
      case 'moderate':
        return Icons.info;
      case 'ordinary':
        return Icons.check;
      default:
        return Icons.help;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = DateTime.parse(timestamp.toString());
      }

      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

// Custom Widgets
class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
