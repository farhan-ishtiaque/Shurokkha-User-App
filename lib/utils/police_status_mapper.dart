import 'package:flutter/material.dart';
import '../models/police_models.dart';

/// Utility class for mapping police report status to UI elements
class PoliceStatusMapper {
  
  /// Get color for status
  static Color getStatusColor(PoliceReportStatus status) {
    final colorCode = status.colorCode;
    return Color(int.parse(colorCode.substring(1), radix: 16) + 0xFF000000);
  }

  /// Get icon for status
  static IconData getStatusIcon(PoliceReportStatus status) {
    switch (status) {
      case PoliceReportStatus.pending:
        return Icons.schedule;
      case PoliceReportStatus.accepted:
        return Icons.assignment_ind;
      case PoliceReportStatus.completed:
        return Icons.check_circle;
      case PoliceReportStatus.fraud:
        return Icons.warning;
    }
  }

  /// Get status badge widget
  static Widget getStatusBadge(PoliceReportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            size: 12,
            color: getStatusColor(status),
          ),
          const SizedBox(width: 4),
          Text(
            status.displayLabel,
            style: TextStyle(
              color: getStatusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get detailed status description
  static String getStatusDescription(PoliceReportStatus status) {
    switch (status) {
      case PoliceReportStatus.pending:
        return 'Your report is being reviewed by the police department. An officer will be assigned soon.';
      case PoliceReportStatus.accepted:
        return 'An officer has been assigned to your case and will begin investigation.';
      case PoliceReportStatus.completed:
        return 'Your case has been successfully resolved and closed.';
      case PoliceReportStatus.fraud:
        return 'This report has been flagged for review due to potential fraudulent content.';
    }
  }

  /// Get status priority for sorting (lower number = higher priority)
  static int getStatusPriority(PoliceReportStatus status) {
    switch (status) {
      case PoliceReportStatus.accepted:
        return 1; // Highest priority - active cases
      case PoliceReportStatus.pending:
        return 2; // Second priority - waiting for assignment
      case PoliceReportStatus.fraud:
        return 3; // Third priority - flagged cases
      case PoliceReportStatus.completed:
        return 4; // Lowest priority - completed cases
    }
  }

  /// Check if status is active (should appear in active tab)
  static bool isActiveStatus(PoliceReportStatus status) {
    return status == PoliceReportStatus.pending || 
           status == PoliceReportStatus.accepted;
  }

  /// Check if status is completed (should appear in completed tab)
  static bool isCompletedStatus(PoliceReportStatus status) {
    return status == PoliceReportStatus.completed || 
           status == PoliceReportStatus.fraud;
  }

  /// Get progress value for status (0.0 to 1.0)
  static double getProgressValue(PoliceReportStatus status) {
    switch (status) {
      case PoliceReportStatus.pending:
        return 0.25;
      case PoliceReportStatus.accepted:
        return 0.5;
      case PoliceReportStatus.completed:
        return 1.0;
      case PoliceReportStatus.fraud:
        return 0.75; // Partial progress since it's flagged
    }
  }

  /// Get timeline steps for status
  static List<StatusStep> getTimelineSteps(PoliceReportStatus currentStatus) {
    return [
      StatusStep(
        title: 'Report Submitted',
        description: 'Your police report has been received',
        status: PoliceReportStatus.pending,
        isCompleted: true,
        isCurrent: currentStatus == PoliceReportStatus.pending,
      ),
      StatusStep(
        title: 'Officer Assigned',
        description: 'An officer has been assigned to your case',
        status: PoliceReportStatus.accepted,
        isCompleted: currentStatus == PoliceReportStatus.accepted ||
                     currentStatus == PoliceReportStatus.completed,
        isCurrent: currentStatus == PoliceReportStatus.accepted,
      ),
      StatusStep(
        title: 'Case Resolved',
        description: 'Your case has been resolved',
        status: PoliceReportStatus.completed,
        isCompleted: currentStatus == PoliceReportStatus.completed,
        isCurrent: currentStatus == PoliceReportStatus.completed,
      ),
    ];
  }
}

/// Represents a step in the status timeline
class StatusStep {
  final String title;
  final String description;
  final PoliceReportStatus status;
  final bool isCompleted;
  final bool isCurrent;

  const StatusStep({
    required this.title,
    required this.description,
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
  });
}
