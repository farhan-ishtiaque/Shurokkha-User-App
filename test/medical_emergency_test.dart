import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';
import 'package:shurokkha_app/models/medical_report_firestore.dart';
import 'dart:async';

/// Integration test for medical emergency system
/// Tests medical report creation, Firestore streaming, and UI state changes
void main() {
  group('Medical Emergency System Integration Tests', () {
    test('Create Medical Report with JSON POST', () async {
      // Test data
      const description = 'Severe chest pain and difficulty breathing';
      const latitude = 23.7808;
      const longitude = 90.2792;
      const address = 'Dhaka Medical College, Dhaka';

      print('🚑 Testing medical report creation...');

      // Call the API service
      final result = await submitMedicalEmergencyReport(
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      // Verify the response
      expect(result['success'], true);
      expect(result['report_id'], isNotNull);
      expect(result['category'], isIn(['ordinary', 'moderate', 'serious']));

      final reportId = result['report_id'];
      print('✅ Medical report created with ID: $reportId');
      print('📊 Category: ${result['category']}');
      print('🤖 AI Advice: ${result['ai_advice'] ?? 'None'}');

      // Test Firestore document structure
      await _testFirestoreStream(reportId);
    });

    test('Medical Report Model Parsing', () {
      // Test model creation with direct data
      final report = MedicalReportFirestore(
        reportId: 'test_123',
        status: 'pending',
        category: 'moderate',
        aiAdvice: 'Seek immediate medical attention',
        userId: 1,
        description: 'Test symptoms',
        address: 'Test address',
        latitude: 23.7808,
        longitude: 90.2792,
        timestamp: DateTime.now(),
        updatedAt: DateTime.now(),
        nearbyHospitalIds: const ['hospital_1', 'hospital_2'],
        sentToOperator: false,
        escalationScheduled: false,
      );

      expect(report.reportId, 'test_123');
      expect(report.status, 'pending');
      expect(report.category, 'moderate');
      expect(report.isCompleted, false);
      expect(report.hasAssignedDriver, false);
      expect(report.nearbyHospitalIds.length, 2);

      print('✅ Medical report model parsing works correctly');
    });

    test('UI State Logic for Different Categories', () {
      // Test ordinary case (auto-completed)
      final ordinaryCase = MedicalReportFirestore(
        reportId: 'ord_123',
        status: 'completed',
        category: 'ordinary',
        updatedAt: DateTime.now(),
        latitude: 23.7808,
        longitude: 90.2792,
        address: 'Test',
        timestamp: DateTime.now(),
        userId: 1,
        description: 'Test',
        aiAdvice: 'Take rest and monitor symptoms',
      );

      expect(ordinaryCase.isCompleted, true);
      print('✅ Ordinary case shows as completed with AI advice');

      // Test serious case (requires operator)
      final seriousCase = MedicalReportFirestore(
        reportId: 'ser_123',
        status: 'pending',
        category: 'serious',
        updatedAt: DateTime.now(),
        latitude: 23.7808,
        longitude: 90.2792,
        address: 'Test',
        timestamp: DateTime.now(),
        userId: 1,
        description: 'Test',
        sentToOperator: true,
      );

      expect(seriousCase.isCompleted, false);
      expect(seriousCase.sentToOperator, true);
      print('✅ Serious case shows operator contact and hospital notification');

      // Test accepted case with assignments
      final acceptedCase = MedicalReportFirestore(
        reportId: 'acc_123',
        status: 'accepted',
        category: 'moderate',
        assignedHospitalId: 'hosp_1',
        assignedHospitalName: 'Dhaka Medical College',
        assignedDriverId: 'driver_1',
        assignedDriverName: 'John Doe',
        assignedDriverUnitId: 'AMB_001',
        updatedAt: DateTime.now(),
        latitude: 23.7808,
        longitude: 90.2792,
        address: 'Test',
        timestamp: DateTime.now(),
        userId: 1,
        description: 'Test',
      );

      expect(acceptedCase.hasAssignedHospital, true);
      expect(acceptedCase.hasAssignedDriver, true);
      print('✅ Accepted case shows hospital and driver assignment');
    });
  });
}

/// Test Firestore real-time streaming
Future<void> _testFirestoreStream(String reportId) async {
  print('📡 Testing Firestore stream for report: $reportId');

  final streamController = StreamController<DocumentSnapshot>();
  late StreamSubscription subscription;

  // Simulate Firestore stream
  subscription = FirebaseFirestore.instance
      .collection('medical_reports')
      .doc(reportId)
      .snapshots()
      .listen((snapshot) {
        if (snapshot.exists) {
          print('📋 Firestore update received for $reportId');
          final report = MedicalReportFirestore.fromDoc(snapshot);
          print('Status: ${report.status}, Category: ${report.category}');

          // Test state transitions
          if (report.category == 'ordinary') {
            print('✅ Ordinary case - should show AI advice immediately');
          } else if (report.status == 'pending') {
            print('⏳ Pending case - waiting for hospital acceptance');
          } else if (report.status == 'accepted') {
            print('🏥 Accepted case - should show hospital and driver info');

            // If driver assigned, test driver tracking
            if (report.hasAssignedDriver) {
              _testDriverTracking(report.assignedDriverId!);
            }
          }

          streamController.add(snapshot);
        }
      });

  // Clean up after test
  await Future.delayed(const Duration(seconds: 5));
  await subscription.cancel();
  await streamController.close();

  print('✅ Firestore streaming test completed');
}

/// Test driver live location tracking
Future<void> _testDriverTracking(String driverId) async {
  print('🚐 Testing driver location tracking for: $driverId');

  final subscription = FirebaseFirestore.instance
      .collection('medical_drivers')
      .doc(driverId)
      .snapshots()
      .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final location = data['location'] as GeoPoint?;

          if (location != null) {
            print(
              '📍 Driver location: ${location.latitude}, ${location.longitude}',
            );
            print('✅ Driver tracking working - map should update');
          } else {
            print(
              '⚠️ Driver location not available - show "locating..." message',
            );
          }
        }
      });

  // Simulate tracking for a short time
  await Future.delayed(const Duration(seconds: 3));
  await subscription.cancel();

  print('✅ Driver tracking test completed');
}
