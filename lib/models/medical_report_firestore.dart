import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Medical Report Model for Firestore documents
/// Matches the canonical medical_reports/{report_id} structure
class MedicalReportFirestore {
  final String reportId;
  final String status; // pending|accepted|completed
  final String category; // ordinary|moderate|serious
  final String? aiAdvice;
  final String? operatorStatus;
  final String? assignedHospitalId;
  final String? assignedHospitalName;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedDriverUnitId;
  final List<String> nearbyHospitalIds;
  final bool sentToOperator;
  final bool escalationScheduled;
  final DateTime? escalationTime;
  final DateTime updatedAt;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final int userId;
  final String description;

  MedicalReportFirestore({
    required this.reportId,
    required this.status,
    required this.category,
    this.aiAdvice,
    this.operatorStatus,
    this.assignedHospitalId,
    this.assignedHospitalName,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriverUnitId,
    this.nearbyHospitalIds = const [],
    this.sentToOperator = false,
    this.escalationScheduled = false,
    this.escalationTime,
    required this.updatedAt,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.userId,
    required this.description,
  });

  /// Create from Firestore DocumentSnapshot with null-safe parsing
  factory MedicalReportFirestore.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MedicalReportFirestore(
      reportId: doc.id,
      status: data['status'] ?? 'pending',
      category: data['category'] ?? 'ordinary',
      aiAdvice: data['ai_advice'],
      operatorStatus: data['operator_status'],
      assignedHospitalId: data['assigned_hospital_id'],
      assignedHospitalName: data['assigned_hospital_name'],
      assignedDriverId: data['assigned_driver_id'],
      assignedDriverName: data['assigned_driver_name'],
      assignedDriverUnitId: data['assigned_driver_unit_id'],
      nearbyHospitalIds: List<String>.from(data['nearby_hospital_ids'] ?? []),
      sentToOperator: data['sent_to_operator'] ?? false,
      escalationScheduled: data['escalation_scheduled'] ?? false,
      escalationTime: data['escalation_time'] != null
          ? (data['escalation_time'] as Timestamp).toDate()
          : null,
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      userId: data['user_id'] ?? 0,
      description: data['description'] ?? '',
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'status': status,
      'category': category,
      'ai_advice': aiAdvice,
      'operator_status': operatorStatus,
      'assigned_hospital_id': assignedHospitalId,
      'assigned_hospital_name': assignedHospitalName,
      'assigned_driver_id': assignedDriverId,
      'assigned_driver_name': assignedDriverName,
      'assigned_driver_unit_id': assignedDriverUnitId,
      'nearby_hospital_ids': nearbyHospitalIds,
      'sent_to_operator': sentToOperator,
      'escalation_scheduled': escalationScheduled,
      'escalation_time': escalationTime != null
          ? Timestamp.fromDate(escalationTime!)
          : null,
      'updated_at': Timestamp.fromDate(updatedAt),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': Timestamp.fromDate(timestamp),
      'user_id': userId,
      'description': description,
    };
  }

  /// Check if case is completed (ordinary auto-completed or status completed)
  bool get isCompleted => category == 'ordinary' || status == 'completed';

  /// Check if case has assigned driver
  bool get hasAssignedDriver =>
      assignedDriverId != null && assignedDriverId!.isNotEmpty;

  /// Check if case has assigned hospital
  bool get hasAssignedHospital =>
      assignedHospitalId != null && assignedHospitalId!.isNotEmpty;

  /// Get status color for UI
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  /// Get category color for UI
  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'serious':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'ordinary':
      default:
        return Colors.green;
    }
  }

  /// Get status icon for UI
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'accepted':
        return Icons.local_hospital;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  @override
  String toString() {
    return 'MedicalReportFirestore(reportId: $reportId, status: $status, category: $category)';
  }
}

/// Driver info from medical_drivers/{driver_id} collection
class MedicalDriverInfo {
  final String driverId;
  final String? name;
  final String? phone;
  final String? unitId;
  final bool isAvailable;
  final GeoPoint? location;
  final DateTime? lastLocationUpdate;

  MedicalDriverInfo({
    required this.driverId,
    this.name,
    this.phone,
    this.unitId,
    this.isAvailable = false,
    this.location,
    this.lastLocationUpdate,
  });

  /// Create from Firestore DocumentSnapshot
  factory MedicalDriverInfo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MedicalDriverInfo(
      driverId: doc.id,
      name: data['name'],
      phone: data['phone'],
      unitId: data['unit_id'],
      isAvailable: data['is_available'] ?? false,
      location: data['location'] as GeoPoint?,
      lastLocationUpdate: data['last_location_update'] != null
          ? (data['last_location_update'] as Timestamp).toDate()
          : null,
    );
  }

  /// Check if driver has valid location
  bool get hasLocation => location != null;

  /// Get location as latitude/longitude
  (double lat, double lng)? get coordinates {
    if (location == null) return null;
    return (location!.latitude, location!.longitude);
  }
}
