import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../Api_Services/police_api_service.dart';
import '../models/police_models.dart';

/// Police Report Details and Tracking Screen
/// Provides real-time status updates, officer information, and progress timeline
/// Supports both anonymous and registered reports with appropriate UI differences
class PoliceReportDetailsScreen extends StatefulWidget {
  final String reportId;
  final bool isAnonymous;
  final Map<String, dynamic> reportData;

  const PoliceReportDetailsScreen({
    super.key,
    required this.reportId,
    required this.isAnonymous,
    required this.reportData,
  });

  @override
  State<PoliceReportDetailsScreen> createState() =>
      _PoliceReportDetailsScreenState();
}

class _PoliceReportDetailsScreenState extends State<PoliceReportDetailsScreen> {
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  Map<String, dynamic>? _currentStatus;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.reportData;
    _setupStatusListener();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Setup real-time Firebase listener for status updates
  void _setupStatusListener() {
    print(
      '🔥 Setting up Firebase listener for police report: ${widget.reportId}',
    );

    _statusSubscription = FirebaseFirestore.instance
        .collection('police_reports')
        .doc(widget.reportId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && mounted) {
              print('📍 Police report status updated');
              setState(() {
                _currentStatus = snapshot.data() as Map<String, dynamic>;
              });
            }
          },
          onError: (error) {
            print('❌ Error listening to police report updates: $error');
          },
        );

    // Backup refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('⏰ Police report status check...');
    });
  }

  /// Call police station
  void _callPoliceStation(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      try {
        await launchUrl(launchUri);
      } catch (e) {
        print('Could not launch $launchUri');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not make call: $e')));
        }
      }
    }
  }

  /// Get status color based on current status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'fraud':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon based on current status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.assignment_ind;
      case 'completed':
        return Icons.check_circle;
      case 'fraud':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  /// Get status text for display
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Assignment';
      case 'accepted':
        return 'Officer Assigned';
      case 'completed':
        return 'Case Resolved';
      case 'fraud':
        return 'Marked as Fraudulent';
      default:
        return status.toUpperCase();
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Police Report #${widget.reportId}'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading report details...'),
            ],
          ),
        ),
      );
    }

    final data = _currentStatus!;
    final status = data['status'] ?? 'pending';
    final operatorStatus = data['operator_status'] ?? 'registered';
    final description = data['description'] ?? 'No description available';
    final category = data['category'] ?? 'General';
    final address = data['address'] ?? 'Location not specified';
    final assignedStation = data['assigned_station'];
    final assignedOfficer = data['assigned_officer_name'];
    final distanceKm = data['distance_km'];
    final mediaAttached = data['media_attached'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Police Report #${widget.reportId}'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              // Firebase listener handles automatic updates
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _getStatusColor(status).withOpacity(0.1),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isAnonymous
                                ? 'Anonymous Report'
                                : 'Registered Report',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),

            // Progress Timeline
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
                      'Progress Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressTimeline(status, operatorStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                      'Report Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Report ID', widget.reportId),
                    _buildDetailRow('Category', category),
                    _buildDetailRow('Status', _getStatusText(status)),
                    _buildDetailRow('Location', address),
                    if (distanceKm != null)
                      _buildDetailRow(
                        'Distance to Station',
                        '${distanceKm} km',
                      ),
                    _buildDetailRow(
                      'Media Evidence',
                      mediaAttached ? 'Yes' : 'No',
                    ),
                    _buildDetailRow(
                      'Submitted',
                      _formatTimestamp(data['timestamp']),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(description),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assignment Information
            if (assignedStation != null || assignedOfficer != null) ...[
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_police,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Assignment Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (assignedStation != null)
                        _buildDetailRow('Police Station', assignedStation),
                      if (assignedOfficer != null)
                        _buildDetailRow('Assigned Officer', assignedOfficer),

                      // Contact button (placeholder - would need phone number from backend)
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Would need actual station phone number
                            _callPoliceStation(
                              '999',
                            ); // Emergency number as fallback
                          },
                          icon: const Icon(Icons.call),
                          label: const Text('Contact Police Station'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
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
              ),
              const SizedBox(height: 16),
            ],

            // Anonymous Report Notice
            if (widget.isAnonymous && status == 'pending') ...[
              Card(
                color: Colors.orange[50],
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Anonymous Report',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your anonymous report is being reviewed by an operator '
                              'before being assigned to the police. This may take longer '
                              'than regular reports.',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
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

            // Emergency Contact
            Card(
              color: Colors.red[50],
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
                        Icon(Icons.emergency, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Emergency?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If this is an ongoing emergency requiring immediate assistance, '
                      'please call the emergency helpline.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _callPoliceStation('999'),
                        icon: const Icon(Icons.call),
                        label: const Text('Call Emergency: 999'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
            ),
          ],
        ),
      ),
    );
  }

  /// Build progress timeline based on report status and type
  Widget _buildProgressTimeline(String status, String operatorStatus) {
    List<TimelineStep> steps = [];

    if (widget.isAnonymous) {
      steps = [
        TimelineStep(
          'Report Submitted',
          true,
          'Anonymous report received',
          Icons.report,
        ),
        TimelineStep(
          'Operator Review',
          operatorStatus == 'assigned',
          operatorStatus == 'assigned'
              ? 'Verified and assigned to police'
              : 'Awaiting verification',
          Icons.verified_user,
        ),
        TimelineStep(
          'Police Assignment',
          status == 'accepted' || status == 'completed',
          status == 'accepted' || status == 'completed'
              ? 'Officer assigned to case'
              : 'Pending officer assignment',
          Icons.local_police,
        ),
        TimelineStep(
          'Case Resolution',
          status == 'completed',
          status == 'completed'
              ? 'Case successfully resolved'
              : 'Investigation in progress',
          Icons.check_circle,
        ),
      ];
    } else {
      steps = [
        TimelineStep(
          'Report Submitted',
          true,
          'Report received and processed',
          Icons.report,
        ),
        TimelineStep(
          'Police Assignment',
          status == 'accepted' || status == 'completed',
          status == 'accepted' || status == 'completed'
              ? 'Officer assigned to case'
              : 'Awaiting officer assignment',
          Icons.local_police,
        ),
        TimelineStep(
          'Investigation',
          status == 'accepted' || status == 'completed',
          status == 'accepted' || status == 'completed'
              ? 'Investigation in progress'
              : 'Pending investigation start',
          Icons.search,
        ),
        TimelineStep(
          'Case Resolution',
          status == 'completed',
          status == 'completed'
              ? 'Case successfully resolved'
              : 'Awaiting resolution',
          Icons.check_circle,
        ),
      ];
    }

    return Column(
      children: steps
          .asMap()
          .entries
          .map(
            (entry) =>
                _buildTimelineItem(entry.value, entry.key < steps.length - 1),
          )
          .toList(),
    );
  }

  /// Build individual timeline step
  Widget _buildTimelineItem(TimelineStep step, bool hasNext) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted ? Colors.green : Colors.grey[300],
              ),
              child: Icon(
                step.isCompleted ? Icons.check : step.icon,
                color: step.isCompleted ? Colors.white : Colors.grey[600],
                size: 18,
              ),
            ),
            if (hasNext)
              Container(width: 2, height: 40, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: step.isCompleted ? Colors.black : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(
                    color: step.isCompleted ? Colors.black87 : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build detail row for report information
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Timeline step data model
class TimelineStep {
  final String title;
  final bool isCompleted;
  final String description;
  final IconData icon;

  TimelineStep(this.title, this.isCompleted, this.description, this.icon);
}
