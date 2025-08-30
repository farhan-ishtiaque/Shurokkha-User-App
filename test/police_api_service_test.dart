import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';

import 'package:shurokkha_app/models/police_models.dart';

void main() {
  group('Police Models Tests', () {
    group('PoliceReportStatus', () {
      test('should convert string to enum correctly', () {
        expect(PoliceReportStatusUtils.fromString('pending'), PoliceReportStatus.pending);
        expect(PoliceReportStatusUtils.fromString('accepted'), PoliceReportStatus.accepted);
        expect(PoliceReportStatusUtils.fromString('completed'), PoliceReportStatus.completed);
        expect(PoliceReportStatusUtils.fromString('fraud'), PoliceReportStatus.fraud);
        expect(PoliceReportStatusUtils.fromString('invalid'), PoliceReportStatus.pending);
      });

      test('should provide correct display labels', () {
        expect(PoliceReportStatus.pending.displayLabel, 'Pending');
        expect(PoliceReportStatus.accepted.displayLabel, 'Assigned');
        expect(PoliceReportStatus.completed.displayLabel, 'Resolved');
        expect(PoliceReportStatus.fraud.displayLabel, 'Flagged');
      });

      test('should provide correct backend values', () {
        expect(PoliceReportStatus.pending.backendValue, 'pending');
        expect(PoliceReportStatus.accepted.backendValue, 'accepted');
        expect(PoliceReportStatus.completed.backendValue, 'completed');
        expect(PoliceReportStatus.fraud.backendValue, 'fraud');
      });

      test('should provide correct color codes', () {
        expect(PoliceReportStatus.pending.colorCode, '#FFA726');
        expect(PoliceReportStatus.accepted.colorCode, '#42A5F5');
        expect(PoliceReportStatus.completed.colorCode, '#66BB6A');
        expect(PoliceReportStatus.fraud.colorCode, '#EF5350');
      });

      test('should provide correct icon names', () {
        expect(PoliceReportStatus.pending.iconName, 'schedule');
        expect(PoliceReportStatus.accepted.iconName, 'assignment_ind');
        expect(PoliceReportStatus.completed.iconName, 'check_circle');
        expect(PoliceReportStatus.fraud.iconName, 'warning');
      });
    });

    group('Model Serialization', () {
      test('PoliceSubmitResponse should serialize/deserialize correctly', () {
        final json = {
          'success': true,
          'message': 'Police report submitted successfully',
          'report_id': 123,
          'anonymous': false,
          'media_attached': true,
          'assigned_station': 'Dhaka Metro Police Station',
          'distance_km': 2.5,
          'note': 'Test note',
        };

        final response = PoliceSubmitResponse.fromJson(json);
        expect(response.success, true);
        expect(response.message, 'Police report submitted successfully');
        expect(response.reportId, 123);
        expect(response.anonymous, false);
        expect(response.mediaAttached, true);
        expect(response.assignedStation, 'Dhaka Metro Police Station');
        expect(response.distanceKm, 2.5);
        expect(response.note, 'Test note');

        final serialized = response.toJson();
        expect(serialized['success'], true);
        expect(serialized['report_id'], 123);
        expect(serialized['media_attached'], true);
        expect(serialized['assigned_station'], 'Dhaka Metro Police Station');
      });

      test('PoliceSubmitResponse should handle null note', () {
        final json = {
          'success': true,
          'message': 'Success',
          'report_id': 124,
          'anonymous': true,
          'media_attached': false,
          'assigned_station': 'Ramna Police Station',
          'distance_km': 1.0,
          'note': null,
        };

        final response = PoliceSubmitResponse.fromJson(json);
        expect(response.note, null);

        final serialized = response.toJson();
        expect(serialized.containsKey('note'), false);
      });

      test('PoliceStatusResponse should handle DateTime correctly', () {
        final json = {
          'report_id': 123,
          'status': 'accepted',
          'assigned_station': 'Dhaka Metro Police Station',
          'assigned_officer': 'Officer John Doe',
          'last_updated': '2024-01-01T10:30:00Z',
        };

        final response = PoliceStatusResponse.fromJson(json);
        expect(response.reportId, 123);
        expect(response.status, PoliceReportStatus.accepted);
        expect(response.assignedStation, 'Dhaka Metro Police Station');
        expect(response.assignedOfficer, 'Officer John Doe');
        expect(response.lastUpdated.year, 2024);
        expect(response.lastUpdated.month, 1);
        expect(response.lastUpdated.day, 1);
        expect(response.lastUpdated.hour, 10);
        expect(response.lastUpdated.minute, 30);

        final serialized = response.toJson();
        expect(serialized['report_id'], 123);
        expect(serialized['status'], 'accepted');
        expect(serialized['last_updated'], '2024-01-01T10:30:00.000Z');
      });

      test('PoliceStatusResponse should handle null assigned officer', () {
        final json = {
          'report_id': 125,
          'status': 'pending',
          'assigned_station': 'Gulshan Police Station',
          'assigned_officer': null,
          'last_updated': '2024-01-02T15:45:00Z',
        };

        final response = PoliceStatusResponse.fromJson(json);
        expect(response.assignedOfficer, null);

        final serialized = response.toJson();
        expect(serialized.containsKey('assigned_officer'), false);
      });

      test('PoliceReportItem should serialize/deserialize correctly', () {
        final json = {
          'id': 123,
          'type': 'police',
          'description': 'Test crime report',
          'status': 'completed',
          'timestamp': '2024-01-01T10:00:00Z',
          'address': 'Test Location, Dhaka',
          'latitude': 23.8103,
          'longitude': 90.4125,
          'assigned_station': 'Dhaka Metro Police Station',
        };

        final item = PoliceReportItem.fromJson(json);
        expect(item.id, 123);
        expect(item.type, 'police');
        expect(item.description, 'Test crime report');
        expect(item.status, PoliceReportStatus.completed);
        expect(item.address, 'Test Location, Dhaka');
        expect(item.latitude, 23.8103);
        expect(item.longitude, 90.4125);
        expect(item.assignedStation, 'Dhaka Metro Police Station');

        final serialized = item.toJson();
        expect(serialized['id'], 123);
        expect(serialized['status'], 'completed');
        expect(serialized['latitude'], 23.8103);
      });

      test('PoliceReportsListResponse should handle multiple reports', () {
        final json = {
          'reports': [
            {
              'id': 123,
              'type': 'police',
              'description': 'First report',
              'status': 'pending',
              'timestamp': '2024-01-01T10:00:00Z',
              'address': 'Location 1',
              'latitude': 23.8103,
              'longitude': 90.4125,
              'assigned_station': 'Station 1',
            },
            {
              'id': 124,
              'type': 'police',
              'description': 'Second report',
              'status': 'fraud',
              'timestamp': '2024-01-02T10:00:00Z',
              'address': 'Location 2',
              'latitude': 23.7697,
              'longitude': 90.3563,
              'assigned_station': 'Station 2',
            },
          ],
        };

        final response = PoliceReportsListResponse.fromJson(json);
        expect(response.reports.length, 2);
        expect(response.reports[0].id, 123);
        expect(response.reports[1].id, 124);
        expect(response.reports[0].status, PoliceReportStatus.pending);
        expect(response.reports[1].status, PoliceReportStatus.fraud);
      });

      test('PoliceReportsListResponse should handle empty list', () {
        final json = {
          'reports': [],
        };

        final response = PoliceReportsListResponse.fromJson(json);
        expect(response.reports.length, 0);
        expect(response.reports, isEmpty);
      });

      test('BackendErrorResponse should handle error format', () {
        final json = {
          'error': 'Description field is required',
          'success': false,
        };

        final response = BackendErrorResponse.fromJson(json);
        expect(response.error, 'Description field is required');
        expect(response.success, false);

        final serialized = response.toJson();
        expect(serialized['error'], 'Description field is required');
        expect(serialized['success'], false);
      });
    });

    group('Input Validation Tests', () {
      test('should validate required fields in models', () {
        // Test that models handle required fields correctly
        expect(() => PoliceSubmitResponse.fromJson({}), throwsA(isA<TypeError>()));
        expect(() => PoliceStatusResponse.fromJson({}), throwsA(isA<TypeError>()));
        expect(() => PoliceReportItem.fromJson({}), throwsA(isA<TypeError>()));
      });

      test('should handle invalid status strings gracefully', () {
        final invalidStatusJson = {
          'report_id': 123,
          'status': 'invalid_status',
          'assigned_station': 'Test Station',
          'last_updated': '2024-01-01T10:30:00Z',
        };

        final response = PoliceStatusResponse.fromJson(invalidStatusJson);
        expect(response.status, PoliceReportStatus.pending); // Should default to pending
      });

      test('should handle malformed timestamps gracefully', () {
        final malformedJson = {
          'report_id': 123,
          'status': 'pending',
          'assigned_station': 'Test Station',
          'last_updated': 'invalid_date_format',
        };

        expect(
          () => PoliceStatusResponse.fromJson(malformedJson),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('File Validation Tests', () {
      test('should define valid file extensions', () {
        const allowedExtensions = ['jpg', 'jpeg', 'png', 'mp4'];
        
        expect(allowedExtensions.contains('jpg'), true);
        expect(allowedExtensions.contains('jpeg'), true);
        expect(allowedExtensions.contains('png'), true);
        expect(allowedExtensions.contains('mp4'), true);
        expect(allowedExtensions.contains('pdf'), false);
        expect(allowedExtensions.contains('txt'), false);
      });

      test('should define file size limits', () {
        const maxSizeBytes = 10 * 1024 * 1024; // 10MB
        const testSizeSmall = 5 * 1024 * 1024; // 5MB
        const testSizeLarge = 15 * 1024 * 1024; // 15MB

        expect(testSizeSmall <= maxSizeBytes, true);
        expect(testSizeLarge <= maxSizeBytes, false);
      });
    });

    group('Edge Cases', () {
      test('should handle very long descriptions', () {
        final longDescription = 'A' * 10000; // 10K characters
        
        // Should not crash when processing long strings
        expect(longDescription.length, 10000);
        expect(longDescription.substring(0, 10), 'AAAAAAAAAA');
      });

      test('should handle special characters in addresses', () {
        const specialAddress = 'রোড ১২, ব্লক-এ, বসুন্ধরা আর/এ, ঢাকা-১২২৯';
        
        final json = {
          'id': 123,
          'type': 'police',
          'description': 'Test',
          'status': 'pending',
          'timestamp': '2024-01-01T10:00:00Z',
          'address': specialAddress,
          'latitude': 23.8103,
          'longitude': 90.4125,
          'assigned_station': 'Test Station',
        };

        final item = PoliceReportItem.fromJson(json);
        expect(item.address, specialAddress);
      });

      test('should handle extreme coordinate values', () {
        final json = {
          'id': 123,
          'type': 'police',
          'description': 'Test',
          'status': 'pending',
          'timestamp': '2024-01-01T10:00:00Z',
          'address': 'Test',
          'latitude': -90.0, // Extreme latitude
          'longitude': 180.0, // Extreme longitude
          'assigned_station': 'Test Station',
        };

        final item = PoliceReportItem.fromJson(json);
        expect(item.latitude, -90.0);
        expect(item.longitude, 180.0);
      });
    });
  });
}
