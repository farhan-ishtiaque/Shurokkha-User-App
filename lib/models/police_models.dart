/// Police report models for backend contract compliance

/// Police report status enum matching backend
enum PoliceReportStatus { pending, accepted, completed, fraud }

/// Utility class for status conversion
class PoliceReportStatusUtils {
  static PoliceReportStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PoliceReportStatus.pending;
      case 'accepted':
        return PoliceReportStatus.accepted;
      case 'completed':
        return PoliceReportStatus.completed;
      case 'fraud':
        return PoliceReportStatus.fraud;
      default:
        return PoliceReportStatus.pending;
    }
  }
}

/// Extension to map backend status to UI labels and colors
extension PoliceReportStatusExtension on PoliceReportStatus {
  String get displayLabel {
    switch (this) {
      case PoliceReportStatus.pending:
        return 'Pending';
      case PoliceReportStatus.accepted:
        return 'Assigned';
      case PoliceReportStatus.completed:
        return 'Resolved';
      case PoliceReportStatus.fraud:
        return 'Flagged';
    }
  }

  String get backendValue {
    switch (this) {
      case PoliceReportStatus.pending:
        return 'pending';
      case PoliceReportStatus.accepted:
        return 'accepted';
      case PoliceReportStatus.completed:
        return 'completed';
      case PoliceReportStatus.fraud:
        return 'fraud';
    }
  }

  String get colorCode {
    switch (this) {
      case PoliceReportStatus.pending:
        return '#FFA726'; // Orange
      case PoliceReportStatus.accepted:
        return '#42A5F5'; // Blue
      case PoliceReportStatus.completed:
        return '#66BB6A'; // Green
      case PoliceReportStatus.fraud:
        return '#EF5350'; // Red
    }
  }

  String get iconName {
    switch (this) {
      case PoliceReportStatus.pending:
        return 'schedule';
      case PoliceReportStatus.accepted:
        return 'assignment_ind';
      case PoliceReportStatus.completed:
        return 'check_circle';
      case PoliceReportStatus.fraud:
        return 'warning';
    }
  }
}

/// Police report submission response model
class PoliceSubmitResponse {
  final bool success;
  final String message;
  final int reportId;
  final bool anonymous;
  final bool mediaAttached;
  final String? assignedStation;
  final double? distanceKm;
  final String? note;

  const PoliceSubmitResponse({
    required this.success,
    required this.message,
    required this.reportId,
    required this.anonymous,
    required this.mediaAttached,
    this.assignedStation,
    this.distanceKm,
    this.note,
  });

  factory PoliceSubmitResponse.fromJson(Map<String, dynamic> json) {
    return PoliceSubmitResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      reportId: json['report_id'] as int,
      anonymous: json['anonymous'] as bool,
      mediaAttached: json['media_attached'] as bool,
      assignedStation: json['assigned_station'] as String?,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'report_id': reportId,
      'anonymous': anonymous,
      'media_attached': mediaAttached,
      'assigned_station': assignedStation,
      'distance_km': distanceKm,
      if (note != null) 'note': note,
    };
  }
}

/// Police report status response model
class PoliceStatusResponse {
  final int reportId;
  final PoliceReportStatus status;
  final String assignedStation;
  final String? assignedOfficer;
  final DateTime lastUpdated;

  const PoliceStatusResponse({
    required this.reportId,
    required this.status,
    required this.assignedStation,
    this.assignedOfficer,
    required this.lastUpdated,
  });

  factory PoliceStatusResponse.fromJson(Map<String, dynamic> json) {
    return PoliceStatusResponse(
      reportId: json['report_id'] as int,
      status: PoliceReportStatusUtils.fromString(json['status'] as String),
      assignedStation: json['assigned_station'] as String,
      assignedOfficer: json['assigned_officer'] as String?,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'status': status.backendValue,
      'assigned_station': assignedStation,
      if (assignedOfficer != null) 'assigned_officer': assignedOfficer,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

/// Police report list item model
class PoliceReportItem {
  final int id;
  final String type;
  final String description;
  final PoliceReportStatus status;
  final DateTime timestamp;
  final String address;
  final double latitude;
  final double longitude;
  final String assignedStation;

  const PoliceReportItem({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.timestamp,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.assignedStation,
  });

  factory PoliceReportItem.fromJson(Map<String, dynamic> json) {
    return PoliceReportItem(
      id: json['id'] as int,
      type: json['type'] as String,
      description: json['description'] as String,
      status: PoliceReportStatusUtils.fromString(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      assignedStation: json['assigned_station'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'status': status.backendValue,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'assigned_station': assignedStation,
    };
  }
}

/// Police reports list response model
class PoliceReportsListResponse {
  final List<PoliceReportItem> reports;

  const PoliceReportsListResponse({required this.reports});

  factory PoliceReportsListResponse.fromJson(Map<String, dynamic> json) {
    final reportsList = json['reports'] as List<dynamic>;
    return PoliceReportsListResponse(
      reports: reportsList
          .map(
            (item) => PoliceReportItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'reports': reports.map((item) => item.toJson()).toList()};
  }
}

/// Backend error response model
class BackendErrorResponse {
  final String error;
  final bool success;

  const BackendErrorResponse({required this.error, required this.success});

  factory BackendErrorResponse.fromJson(Map<String, dynamic> json) {
    return BackendErrorResponse(
      error: json['error'] as String,
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'error': error, 'success': success};
  }
}
