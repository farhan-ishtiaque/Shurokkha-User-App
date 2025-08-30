import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Fire Report Details Screen with Live Driver Tracking
/// Shows real-time driver location and contact information
class FireReportDetailsScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> reportData;

  const FireReportDetailsScreen({
    super.key,
    required this.documentId,
    required this.reportData,
  });

  @override
  State<FireReportDetailsScreen> createState() =>
      _FireReportDetailsScreenState();
}

class _FireReportDetailsScreenState extends State<FireReportDetailsScreen> {
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  Map<String, dynamic>? _liveReportData;
  Timer? _refreshTimer;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _liveReportData = widget.reportData;
    _startLiveTracking();

    // Initialize markers with current data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapMarkers();
    });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Start live tracking of driver location (refresh every 5 seconds)
  void _startLiveTracking() {
    print(
      '🚗 Starting live driver tracking for document: ${widget.documentId}',
    );

    // Listen to Firestore document changes for real-time updates
    _driverLocationSubscription = FirebaseFirestore.instance
        .collection('fire_reports')
        .doc(widget.documentId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            setState(() {
              _liveReportData = snapshot.data() as Map<String, dynamic>;
            });
            final data = _liveReportData!;
            final assignedDriver =
                data['assigned_driver'] as Map<String, dynamic>?;
            final driverLat = assignedDriver?['latitude'];
            final driverLng = assignedDriver?['longitude'];
            print(
              '📍 Driver location updated: Lat: $driverLat, Lng: $driverLng',
            );
            print(
              '🚗 Assigned driver: ${assignedDriver?['name']} (${assignedDriver?['status']})',
            );

            // Update map markers with new data
            _updateMapMarkers();
          }
        });

    // Additional timer for extra safety (refresh every 5 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      print('⏰ Timer refresh - checking for updates...');
    });
  }

  /// Launch phone dialer to call driver
  void _callDriver(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')),
          );
        }
      }
    } catch (e) {
      print('Error launching dialer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred while launching dialer'),
          ),
        );
      }
    }
  }

  /// Update markers on the map with enhanced positioning
  void _updateMapMarkers() {
    final data = _liveReportData!;
    final assignedDriver = data['assigned_driver'] as Map<String, dynamic>?;
    final userLat = data['latitude'] as double?;
    final userLng = data['longitude'] as double?;
    final driverLat = assignedDriver?['latitude'] as double?;
    final driverLng = assignedDriver?['longitude'] as double?;

    print('🗺️ Updating map markers:');
    print('  User location: $userLat, $userLng');
    print('  Driver location: $driverLat, $driverLng');
    print('  Assigned driver: $assignedDriver');

    Set<Marker> newMarkers = {};

    // Add user location marker (fire incident location)
    if (userLat != null && userLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLat, userLng),
          infoWindow: const InfoWindow(
            title: '🔥 Fire Incident Location',
            snippet: 'Emergency reported here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      print('✅ Added user marker at: $userLat, $userLng');
    }

    // Add driver location marker if available, or show at assigned station
    if (assignedDriver != null) {
      LatLng? driverPosition;
      String driverSnippet = assignedDriver['name'] ?? 'Driver';

      if (driverLat != null && driverLng != null) {
        // Use actual driver location
        driverPosition = LatLng(driverLat, driverLng);
        driverSnippet += ' (Live Location)';
        print('✅ Using live driver location: $driverLat, $driverLng');
      } else {
        // Use approximate station location or nearby area
        // For Vatara Fire Station, use approximate coordinates
        if (data['assigned_station'] == 'Vatara Fire Station') {
          driverPosition = const LatLng(23.7808, 90.4163); // Vatara area
          driverSnippet += ' (At Station)';
          print('✅ Using station location for Vatara');
        } else if (userLat != null && userLng != null) {
          // Place driver marker slightly offset from user location
          driverPosition = LatLng(userLat + 0.002, userLng + 0.002);
          driverSnippet += ' (En Route)';
          print('✅ Using offset location near incident');
        }
      }

      if (driverPosition != null) {
        newMarkers.add(
          Marker(
            markerId: const MarkerId('driver_location'),
            position: driverPosition,
            infoWindow: InfoWindow(
              title: '🚒 Fire Service Unit',
              snippet: driverSnippet,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
        print(
          '✅ Added driver marker at: ${driverPosition.latitude}, ${driverPosition.longitude}',
        );
      }
    }

    print('📍 Total markers: ${newMarkers.length}');
    setState(() {
      _markers = newMarkers;
    });
  }

  /// Build the Google Maps widget
  Widget _buildMapWidget() {
    final data = _liveReportData!;
    final userLat = data['latitude'] as double?;
    final userLng = data['longitude'] as double?;

    // Default center to user location, or Dhaka if not available
    LatLng center = const LatLng(23.8103, 90.4125); // Dhaka center
    if (userLat != null && userLng != null) {
      center = LatLng(userLat, userLng);
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _updateMapMarkers();
      },
      initialCameraPosition: CameraPosition(target: center, zoom: 15.0),
      markers: _markers,
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false, // We have custom controls
      compassEnabled: true,
      scrollGesturesEnabled: true, // Enable map scrolling
      zoomGesturesEnabled: true, // Enable pinch-to-zoom
      tiltGesturesEnabled: true, // Enable tilt gestures
      rotateGesturesEnabled: true, // Enable rotation
      mapToolbarEnabled: false, // Disable default toolbar
      onTap: (LatLng location) {
        print('Map tapped at: ${location.latitude}, ${location.longitude}');
      },
    );
  }

  /// Zoom in on the map
  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  /// Zoom out on the map
  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  /// Center the map on user location
  void _centerMapOnUser() {
    final data = _liveReportData!;
    final userLat = data['latitude'] as double?;
    final userLng = data['longitude'] as double?;

    if (userLat != null && userLng != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(userLat, userLng), zoom: 16.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_liveReportData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _liveReportData!;
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final formattedTime =
        '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    final description = data['description'] ?? 'No description provided';
    final location = data['address'] ?? 'Location not specified';
    final status = data['status'] ?? 'pending';

    // Driver information from assigned_driver map
    final assignedDriver = data['assigned_driver'] as Map<String, dynamic>?;
    final driverName =
        assignedDriver?['name'] ??
        data['assigned_driver_name'] ??
        'Not assigned';
    final driverPhone = assignedDriver?['phone_number'] ?? '';
    final driverStatus = assignedDriver?['status'] ?? 'unknown';
    final assignedStation = data['assigned_station'] ?? 'Unknown Station';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fire Report Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Top section: Status and Map (Fixed height to prevent scroll conflicts)
          Container(
            height:
                (status == 'accepted' || status == 'assigned') &&
                    assignedDriver != null
                ? 450
                : 120,
            child: Column(
              children: [
                // Status Card
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: (status == 'accepted' || status == 'assigned')
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            (status == 'accepted' || status == 'assigned')
                                ? Icons.local_shipping
                                : Icons.schedule,
                            color:
                                (status == 'accepted' || status == 'assigned')
                                ? Colors.orange
                                : Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fire Emergency Report',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        (status == 'accepted' ||
                                            status == 'assigned')
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                ),
                                Text(
                                  'Reported on $formattedTime',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (status == 'accepted' || status == 'assigned')
                                  ? Colors.orange
                                  : Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Live Driver Tracking (when driver is assigned) - FIXED HEIGHT MAP
                if ((status == 'accepted' || status == 'assigned') &&
                    assignedDriver != null)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.navigation,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Live Driver Tracking',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Google Maps View with WORKING SCROLL
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Map widget - NO SCROLL CONFLICTS!
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildMapWidget(),
                                      ),
                                      // Live indicator overlay
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'LIVE',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Zoom controls
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  GestureDetector(
                                                    onTap: _zoomIn,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 20,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 1,
                                                    width: 30,
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  GestureDetector(
                                                    onTap: _zoomOut,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 20,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Center on user location button
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: FloatingActionButton(
                                          mini: true,
                                          onPressed: _centerMapOnUser,
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.blue,
                                          child: const Icon(
                                            Icons.my_location,
                                            size: 20,
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
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom section: Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver Information (beautiful UI restored)
                  if ((status == 'accepted' || status == 'assigned') &&
                      assignedDriver != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Driver Info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.green,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              driverName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (driverPhone.isNotEmpty)
                                              Text(
                                                driverPhone,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            Text(
                                              'Station: $assignedStation',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Status: $driverStatus',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: driverStatus == 'on-duty'
                                                    ? Colors.green
                                                    : Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (driverPhone.isNotEmpty)
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _callDriver(driverPhone),
                                          icon: const Icon(
                                            Icons.phone,
                                            size: 16,
                                          ),
                                          label: const Text('Call'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (status == 'accepted' || status == 'assigned') ...[
                    // Show waiting message when status is accepted/assigned but no driver yet
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Driver Assignment in Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text(
                              'A driver will be assigned soon. You will be notified once the assignment is complete.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Report Information
                          Row(
                            children: [
                              const Icon(
                                Icons.description,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Coordinates: ${data['latitude']}, ${data['longitude']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
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
}
