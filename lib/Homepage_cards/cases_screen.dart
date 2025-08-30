import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Services/api_service.dart';
import '../widgets/medical_case_widgets.dart';
import 'fire_report_details.dart';
import 'medical_report_details.dart';
import 'police_report_details.dart';
import 'police_report_card.dart';

/// Enhanced Main Cases Screen with Police Reports Support
/// Displays Fire, Medical, and Police reports in two tabs: Active and Completed
/// Real-time updates from Firestore with comprehensive filtering
class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? currentUsername;
  int? currentUserId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch current user ID from Django backend API
  Future<void> _getCurrentUser() async {
    try {
      print('🔍 Getting current user...');
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      print('👤 Username from prefs: $username');

      // Get user profile to extract user_id from Django API
      print('📡 Fetching user profile from /api/app-user/profile/...');
      final userProfile = await getUserProfile();
      print('📋 User profile response: $userProfile');

      if (userProfile != null && userProfile['id'] != null) {
        setState(() {
          currentUsername = username;
          currentUserId = userProfile['id'];
          isLoading = false;
        });
        print('✅ Current user ID: $currentUserId');
      } else {
        print('❌ Failed to get user profile or user ID is null');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Error getting current user: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cases',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Active Cases'),
            Tab(icon: Icon(Icons.check_circle), text: 'Completed Cases'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentUserId == null
          ? const Center(
              child: Text(
                'Unable to load user information.\nPlease try logging in again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Active Cases Tab (pending, accepted, assigned)
                CasesListView(
                  userId: currentUserId!,
                  statusFilter: ['pending', 'accepted', 'assigned'],
                  isActiveTab: true,
                ),
                // Completed Cases Tab (completed, fraud)
                CasesListView(
                  userId: currentUserId!,
                  statusFilter: ['completed', 'fraud'],
                  isActiveTab: false,
                ),
              ],
            ),
    );
  }
}

/// Reusable Widget for Cases List View
/// Handles Firestore queries and real-time updates
class CasesListView extends StatelessWidget {
  final int userId;
  final List<String> statusFilter;
  final bool isActiveTab;

  const CasesListView({
    super.key,
    required this.userId,
    required this.statusFilter,
    required this.isActiveTab,
  });

  /// Get fire reports from Firestore filtered by user_id and status
  Stream<QuerySnapshot> _getFireReports() {
    print(
      '🔥 Querying fire_reports for user_id: $userId, status: $statusFilter',
    );
    print('🔥 User ID type: ${userId.runtimeType}');

    return FirebaseFirestore.instance
        .collection('fire_reports')
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: statusFilter)
        .snapshots();
  }

  /// Get medical reports from Firestore filtered by user_id and status
  Stream<QuerySnapshot> _getMedicalReports() {
    print(
      '🚑 Querying medical_reports for user_id: $userId, status: $statusFilter',
    );
    print('🚑 User ID type: ${userId.runtimeType}');

    return FirebaseFirestore.instance
        .collection('medical_reports')
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: statusFilter)
        .snapshots();
  }

  /// Get police reports from Firestore filtered by user_id and status
  Stream<QuerySnapshot> _getPoliceReports() {
    print(
      '🚔 Querying police_reports for user_id: $userId, status: $statusFilter',
    );
    print('🚔 User ID type: ${userId.runtimeType}');

    return FirebaseFirestore.instance
        .collection('police_reports')
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: statusFilter)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Combined Reports Section (Fire, Medical, and Police)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getFireReports(),
            builder: (context, fireSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _getMedicalReports(),
                builder: (context, medicalSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _getPoliceReports(),
                    builder: (context, policeSnapshot) {
                      if (fireSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          medicalSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          policeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (fireSnapshot.hasError ||
                          medicalSnapshot.hasError ||
                          policeSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading reports: ${fireSnapshot.error ?? medicalSnapshot.error ?? policeSnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      // Combine documents from all three streams
                      final List<DocumentSnapshot> allReports = [];

                      // Add fire reports
                      if (fireSnapshot.hasData &&
                          fireSnapshot.data!.docs.isNotEmpty) {
                        allReports.addAll(fireSnapshot.data!.docs);
                        print(
                          '🔥 Found ${fireSnapshot.data!.docs.length} fire reports',
                        );
                        for (var doc in fireSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          print(
                            '🔥 Fire report ID: ${doc.id}, user_id: ${data['user_id']}, status: ${data['status']}',
                          );
                        }
                      }

                      // Add medical reports
                      if (medicalSnapshot.hasData &&
                          medicalSnapshot.data!.docs.isNotEmpty) {
                        allReports.addAll(medicalSnapshot.data!.docs);
                        print(
                          '🚑 Found ${medicalSnapshot.data!.docs.length} medical reports',
                        );
                        for (var doc in medicalSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          print(
                            '🚑 Medical report ID: ${doc.id}, user_id: ${data['user_id']}, status: ${data['status']}',
                          );
                        }
                      }

                      // Add police reports
                      if (policeSnapshot.hasData &&
                          policeSnapshot.data!.docs.isNotEmpty) {
                        allReports.addAll(policeSnapshot.data!.docs);
                        print(
                          '� Found ${policeSnapshot.data!.docs.length} police reports',
                        );
                        for (var doc in policeSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          print(
                            '🚔 Police report ID: ${doc.id}, user_id: ${data['user_id']}, status: ${data['status']}',
                          );
                        }
                      }

                      if (allReports.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Sort reports by timestamp in descending order (newest first)
                      allReports.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['timestamp'] as Timestamp?;
                        final bTime = bData['timestamp'] as Timestamp?;

                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;

                        return bTime.compareTo(aTime);
                      });

                      return ListView.builder(
                        itemCount: allReports.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final doc = allReports[index];
                          final data = doc.data() as Map<String, dynamic>;

                          // Determine report type based on collection
                          final collectionId = doc.reference.parent.id;

                          switch (collectionId) {
                            case 'fire_reports':
                              return FireReportCard(
                                data: data,
                                documentId: doc.id,
                                isActiveTab: isActiveTab,
                              );
                            case 'medical_reports':
                              return MedicalReportCard(
                                data: data,
                                documentId: doc.id,
                                isActiveTab: isActiveTab,
                              );
                            case 'police_reports':
                              return PoliceReportCard(
                                report: {'data': data, 'id': doc.id},
                              );
                            default:
                              return Container(); // Fallback for unknown types
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActiveTab ? Icons.pending_actions : Icons.check_circle,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isActiveTab ? 'No active cases found' : 'No completed cases found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isActiveTab
                ? 'You don\'t have any ongoing emergency reports.'
                : 'No completed emergency reports yet.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Individual Fire Report Card Widget
/// Handles tap interactions based on status
class FireReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentId;
  final bool isActiveTab;

  const FireReportCard({
    super.key,
    required this.data,
    required this.documentId,
    required this.isActiveTab,
  });

  /// Handle card tap based on status
  void _handleCardTap(BuildContext context) {
    final status = data['status'] ?? 'pending';

    if (status == 'accepted' || status == 'assigned') {
      // Navigate to details screen for accepted/assigned cases
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FireReportDetailsScreen(documentId: documentId, reportData: data),
        ),
      );
    } else if (status == 'completed' || status == 'fraud') {
      // Show message for completed/fraud cases
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'completed'
                ? 'This case has been completed.'
                : 'This case has been marked as fraud.',
          ),
          backgroundColor: status == 'completed' ? Colors.green : Colors.red,
        ),
      );
    } else {
      // Pending cases - show info
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This case is pending assignment.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// Get status color based on status value
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'fraud':
        return Colors.red;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  /// Get status icon based on status value
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'accepted':
        return Icons.local_shipping;
      case 'assigned':
        return Icons.assignment_turned_in;
      case 'fraud':
        return Icons.warning;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final formattedTime =
        '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    final description = data['description'] ?? 'No description provided';
    final location = data['address'] ?? 'Location not specified';
    final status = data['status'] ?? 'pending';
    final reportId = data['report_id'] ?? documentId;

    // Determine if card should be clickable
    final isClickable = status == 'accepted' || status == 'assigned';
    final isCompleted = status == 'completed' || status == 'fraud';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isCompleted
          ? Colors.grey.shade100
          : const Color.fromARGB(255, 255, 240, 245),
      elevation: isCompleted ? 2 : 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _handleCardTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isCompleted ? 0.7 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Image.asset(
                        'assets/images/firedept_logo.png',
                        width: 35,
                        height: 35,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Fire Emergency',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isClickable) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.touch_app,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'ID: $reportId',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, thickness: 0.5),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Show driver info for accepted and assigned cases
                if ((status == 'accepted' || status == 'assigned') &&
                    data['driver_name'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Driver: ${data['driver_name']} • ${data['driver_phone']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        if (isClickable)
                          const Text(
                            'Tap for details',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
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
      ),
    );
  }
}

/// Individual Medical Report Card Widget
/// Handles medical emergency cases with real-time updates
class MedicalReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentId;
  final bool isActiveTab;

  const MedicalReportCard({
    super.key,
    required this.data,
    required this.documentId,
    required this.isActiveTab,
  });

  /// Handle card tap based on medical case status
  void _handleCardTap(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final category = data['category'] ?? 'ordinary';

    if (status == 'accepted' ||
        (status == 'pending' && category != 'ordinary')) {
      // Navigate to medical details screen for trackable cases
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicalReportDetailsScreen(
            documentId: documentId,
            reportData: data,
          ),
        ),
      );
    } else if (status == 'completed' || category == 'ordinary') {
      // Show message for completed/ordinary cases
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == 'ordinary'
                ? 'This case was handled automatically with AI advice.'
                : 'This medical case has been completed.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Pending cases - show info
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This medical case is being processed.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final formattedTime =
        '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    final description = data['description'] ?? 'No description provided';
    final location = data['address'] ?? 'Location not specified';
    final status = data['status'] ?? 'pending';
    final category = data['category'] ?? 'ordinary';
    final reportId = data['report_id'] ?? documentId;
    final aiAdvice = data['ai_advice'];

    // Determine if card should be clickable
    final isClickable =
        status == 'accepted' || (status == 'pending' && category != 'ordinary');
    final isCompleted = status == 'completed' || category == 'ordinary';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isCompleted
          ? Colors.grey.shade100
          : const Color.fromARGB(255, 240, 255, 245),
      elevation: isCompleted ? 2 : 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _handleCardTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isCompleted ? 0.7 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Image.asset(
                        'assets/images/medical_logo.png',
                        width: 35,
                        height: 35,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Medical Emergency',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.teal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isClickable) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.touch_app,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'ID: $reportId',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 1,
                      child: CaseStatusChipRow(
                        status: status,
                        category: category,
                        sentToOperator: data['sent_to_operator'] ?? false,
                        escalationScheduled:
                            data['escalation_scheduled'] ?? false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, thickness: 0.5),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Show AI advice as Instructions when available
                if (aiAdvice != null &&
                    aiAdvice.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instructions:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              aiAdvice.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Show hospital info for accepted cases
                if (status == 'accepted' &&
                    data['assigned_hospital_name'] != null) ...[
                  const SizedBox(height: 8),
                  HospitalCard(
                    hospitalId: data['assigned_hospital_id'],
                    hospitalName: data['assigned_hospital_name'],
                  ),
                ],

                // Show driver info for accepted cases with assigned driver
                if (status == 'accepted' &&
                    data['assigned_driver_name'] != null) ...[
                  const SizedBox(height: 8),
                  DriverCard(
                    driverId: data['assigned_driver_id']?.toString(),
                    driverName: data['assigned_driver_name'],
                    driverUnitId: data['assigned_driver_unit_id']?.toString(),
                  ),
                ],

                // Show waiting message for pending moderate/serious cases
                if (status == 'pending' && category != 'ordinary') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category == 'serious'
                                ? 'Contacting operator and all nearby hospitals...'
                                : 'Waiting for hospital acceptance...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        if (isClickable)
                          const Text(
                            'Tap for details',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
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
      ),
    );
  }
}
