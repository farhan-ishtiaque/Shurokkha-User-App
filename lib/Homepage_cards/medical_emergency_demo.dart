import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Api_Services/api_service.dart';
import '../models/medical_report_firestore.dart';
import '../widgets/medical_case_widgets.dart';
import 'dart:async';

/// Demo screen for testing medical emergency system
/// Demonstrates report creation, real-time updates, and UI state changes
class MedicalEmergencyDemoScreen extends StatefulWidget {
  const MedicalEmergencyDemoScreen({super.key});

  @override
  State<MedicalEmergencyDemoScreen> createState() =>
      _MedicalEmergencyDemoScreenState();
}

class _MedicalEmergencyDemoScreenState
    extends State<MedicalEmergencyDemoScreen> {
  String? _currentReportId;
  MedicalReportFirestore? _currentReport;
  MedicalDriverInfo? _currentDriver;
  StreamSubscription<DocumentSnapshot>? _reportSubscription;
  StreamSubscription<DocumentSnapshot>? _driverSubscription;
  bool _isCreatingReport = false;
  final List<String> _logMessages = [];

  @override
  void dispose() {
    _reportSubscription?.cancel();
    _driverSubscription?.cancel();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.insert(0, '${DateTime.now().toLocal()}: $message');
      if (_logMessages.length > 50) {
        _logMessages.removeLast();
      }
    });
    print(message);
  }

  /// Demo: Create a medical report with JSON POST
  Future<void> _createMedicalReport() async {
    setState(() => _isCreatingReport = true);

    try {
      _addLog('🚑 Creating medical report with JSON POST...');

      final result = await submitMedicalEmergencyReport(
        description: 'Demo: Severe chest pain and difficulty breathing',
        latitude: 23.7808,
        longitude: 90.2792,
        address: 'Demo Location - Dhaka Medical College, Dhaka',
      );

      if (result['success'] == true) {
        final reportId = result['report_id'];
        final category = result['category'];
        final aiAdvice = result['ai_advice'];

        _addLog('✅ Report created successfully!');
        _addLog('📊 Report ID: $reportId');
        _addLog('🏷️ Category: $category');
        if (aiAdvice != null) {
          _addLog('🤖 AI Advice: $aiAdvice');
        }

        setState(() => _currentReportId = reportId);
        _startReportTracking(reportId);
      } else {
        _addLog('❌ Failed to create report: ${result['error']}');
      }
    } catch (e) {
      _addLog('💥 Error creating report: $e');
    } finally {
      setState(() => _isCreatingReport = false);
    }
  }

  /// Start tracking report updates in real-time
  void _startReportTracking(String reportId) {
    _addLog('📡 Starting real-time tracking for report: $reportId');

    _reportSubscription = FirebaseFirestore.instance
        .collection('medical_reports')
        .doc(reportId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              _addLog('📋 Report update received');
              final report = MedicalReportFirestore.fromDoc(snapshot);

              setState(() => _currentReport = report);

              _addLog(
                'Status: ${report.status} | Category: ${report.category}',
              );

              // Log state changes
              if (report.category == 'ordinary') {
                _addLog('🟢 Ordinary case - auto-completed with AI advice');
              } else if (report.status == 'pending') {
                _addLog('🟡 Pending - waiting for hospital acceptance');
                if (report.sentToOperator) {
                  _addLog('👤 Operator has been notified');
                }
                if (report.escalationScheduled) {
                  _addLog('⚠️ Escalation scheduled');
                }
              } else if (report.status == 'accepted') {
                _addLog('🟠 Accepted by hospital');
                if (report.hasAssignedHospital) {
                  _addLog('🏥 Hospital: ${report.assignedHospitalName}');
                }
                if (report.hasAssignedDriver) {
                  _addLog('🚐 Driver assigned: ${report.assignedDriverName}');
                  _startDriverTracking(report.assignedDriverId!);
                }
              } else if (report.status == 'completed') {
                _addLog('🟢 Case completed');
                _stopDriverTracking();
              }
            }
          },
          onError: (error) {
            _addLog('❌ Error in report stream: $error');
          },
        );
  }

  /// Start tracking driver location updates
  void _startDriverTracking(String driverId) {
    _addLog('🚐 Starting driver location tracking: $driverId');

    _driverSubscription?.cancel();
    _driverSubscription = FirebaseFirestore.instance
        .collection('medical_drivers')
        .doc(driverId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final driver = MedicalDriverInfo.fromDoc(snapshot);
              setState(() => _currentDriver = driver);

              if (driver.hasLocation) {
                final coords = driver.coordinates!;
                _addLog(
                  '📍 Driver location updated: ${coords.$1}, ${coords.$2}',
                );
              } else {
                _addLog('⚠️ Driver location not available');
              }
            }
          },
          onError: (error) {
            _addLog('❌ Error in driver stream: $error');
          },
        );
  }

  /// Stop driver tracking
  void _stopDriverTracking() {
    _driverSubscription?.cancel();
    setState(() => _currentDriver = null);
    _addLog('🛑 Driver tracking stopped');
  }

  /// Simulate hospital acceptance (for demo purposes)
  Future<void> _simulateHospitalAcceptance() async {
    if (_currentReportId == null) return;

    _addLog('🏥 Simulating hospital acceptance...');

    try {
      // Update Firestore document to simulate hospital acceptance
      await FirebaseFirestore.instance
          .collection('medical_reports')
          .doc(_currentReportId!)
          .update({
            'status': 'accepted',
            'assigned_hospital_id': 'demo_hospital_1',
            'assigned_hospital_name': 'Demo General Hospital',
            'updated_at': FieldValue.serverTimestamp(),
          });

      _addLog('✅ Hospital acceptance simulated');
    } catch (e) {
      _addLog('❌ Error simulating hospital acceptance: $e');
    }
  }

  /// Simulate driver assignment (for demo purposes)
  Future<void> _simulateDriverAssignment() async {
    if (_currentReportId == null) return;

    _addLog('🚐 Simulating driver assignment...');

    try {
      // Update Firestore document to simulate driver assignment
      await FirebaseFirestore.instance
          .collection('medical_reports')
          .doc(_currentReportId!)
          .update({
            'assigned_driver_id': 'demo_driver_1',
            'assigned_driver_name': 'John Doe',
            'assigned_driver_unit_id': 'AMB_001',
            'updated_at': FieldValue.serverTimestamp(),
          });

      // Create demo driver document with location
      await FirebaseFirestore.instance
          .collection('medical_drivers')
          .doc('demo_driver_1')
          .set({
            'name': 'John Doe',
            'phone': '+8801712345678',
            'unit_id': 'AMB_001',
            'is_available': false,
            'location': const GeoPoint(23.7858, 90.2836), // Near Dhaka Medical
            'last_location_update': FieldValue.serverTimestamp(),
          });

      _addLog('✅ Driver assignment simulated');
    } catch (e) {
      _addLog('❌ Error simulating driver assignment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Emergency Demo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Demo Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isCreatingReport
                              ? null
                              : _createMedicalReport,
                          child: _isCreatingReport
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Report'),
                        ),
                        if (_currentReport?.status == 'pending')
                          ElevatedButton(
                            onPressed: _simulateHospitalAcceptance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('Simulate Hospital Accept'),
                          ),
                        if (_currentReport?.status == 'accepted' &&
                            !_currentReport!.hasAssignedDriver)
                          ElevatedButton(
                            onPressed: _simulateDriverAssignment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Simulate Driver Assign'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current report status
            if (_currentReport != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Report Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CaseStatusChipRow(
                        status: _currentReport!.status,
                        category: _currentReport!.category,
                        escalationScheduled:
                            _currentReport!.escalationScheduled,
                        sentToOperator: _currentReport!.sentToOperator,
                      ),
                      const SizedBox(height: 12),

                      // Show AI advice for completed cases
                      if (_currentReport!.isCompleted &&
                          _currentReport!.aiAdvice != null)
                        AiAdviceCard(aiAdvice: _currentReport!.aiAdvice),

                      // Show hospital info
                      if (_currentReport!.hasAssignedHospital) ...[
                        const SizedBox(height: 8),
                        HospitalCard(
                          hospitalId: _currentReport!.assignedHospitalId,
                          hospitalName: _currentReport!.assignedHospitalName,
                        ),
                      ],

                      // Show driver info
                      if (_currentReport!.hasAssignedDriver) ...[
                        const SizedBox(height: 8),
                        DriverCard(
                          driverId: _currentReport!.assignedDriverId,
                          driverName: _currentReport!.assignedDriverName,
                          driverUnitId: _currentReport!.assignedDriverUnitId,
                        ),

                        // Driver location status
                        if (_currentDriver != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _currentDriver!.hasLocation
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentDriver!.hasLocation
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _currentDriver!.hasLocation
                                      ? Icons.gps_fixed
                                      : Icons.gps_off,
                                  size: 16,
                                  color: _currentDriver!.hasLocation
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentDriver!.hasLocation
                                        ? 'Driver location: ${_currentDriver!.coordinates!.$1.toStringAsFixed(4)}, ${_currentDriver!.coordinates!.$2.toStringAsFixed(4)}'
                                        : 'Waiting for driver location...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _currentDriver!.hasLocation
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Log messages
            const Text(
              'Real-time Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _logMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'No log messages yet.\nCreate a medical report to start testing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _logMessages[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
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
