import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/police_models.dart';

const String baseUrl = 'https://ks-marshall-nsw-controllers.trycloudflare.com';

/// Police API service with strict backend contract compliance
/// Uses DRF TokenAuth and matches exact backend endpoints
class PoliceApiService {
  static const Duration _timeout = Duration(seconds: 30);
  static final http.Client _client = http.Client();

  /// Get authentication token from storage
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Create headers with TokenAuth
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    return {'Authorization': 'Token $token'};
  }

  /// Submit police report - POST /api/users/emergency/submit-police-report/
  /// Single media file, exact backend contract
  static Future<PoliceSubmitResponse> submitPoliceReport({
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    bool anonymous = false,
    File? media,
  }) async {
    try {
      print('  Submitting police report...');
      print('  Location: $address ($latitude, $longitude)');
      print('  Anonymous: $anonymous');
      print('  Media: ${media?.path ?? 'none'}');

      // Validate media file if provided
      if (media != null) {
        await _validateMediaFile(media);
      }

      final uri = Uri.parse(
        '$baseUrl/api/users/emergency/submit-police-report/',
      );
      final headers = await _getAuthHeaders();

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields['description'] = description
        ..fields['address'] = address
        ..fields['latitude'] = latitude.toString()
        ..fields['longitude'] = longitude.toString()
        ..fields['anonymous'] = anonymous.toString();

      // Add single media file if provided
      if (media != null) {
        request.files.add(
          await http.MultipartFile.fromPath('media', media.path),
        );
      }

      print(' Sending request to: ${uri.toString()}');
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print(' Response status: ${response.statusCode}');
      print(' Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final submitResponse = PoliceSubmitResponse.fromJson(jsonData);

        print(' Police report submitted successfully');
        print(' Report ID: ${submitResponse.reportId}');

        return submitResponse;
      } else {
        // Handle backend error response
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorResponse = BackendErrorResponse.fromJson(errorData);
          throw Exception('Server error: ${errorResponse.error}');
        } catch (e) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print(' Error submitting police report: $e');
      rethrow;
    }
  }

  /// Get police report status - GET /api/users/emergency/report-status/{report_id}/
  static Future<PoliceStatusResponse> getPoliceReportStatus(
    int reportId,
  ) async {
    try {
      print(' Getting status for report ID: $reportId');

      final uri = Uri.parse(
        '$baseUrl/api/users/emergency/report-status/$reportId/',
      );
      final headers = await _getAuthHeaders();

      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      print(' Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final statusResponse = PoliceStatusResponse.fromJson(jsonData);

        print(
          ' Status retrieved successfully: ${statusResponse.status.displayLabel}',
        );

        return statusResponse;
      } else if (response.statusCode == 404) {
        throw Exception('Report not found');
      } else {
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorResponse = BackendErrorResponse.fromJson(errorData);
          throw Exception('Server error: ${errorResponse.error}');
        } catch (e) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print(' Error getting report status: $e');
      rethrow;
    }
  }

  /// Get user police reports - GET /api/users/emergency/user-reports/
  /// No pagination, fetch all and sort client-side
  static Future<List<PoliceReportItem>> getUserPoliceReports() async {
    try {
      print(' Getting user police reports...');

      final uri = Uri.parse('$baseUrl/api/users/emergency/user-reports/');
      final headers = await _getAuthHeaders();

      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      print(' Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final listResponse = PoliceReportsListResponse.fromJson(jsonData);

        // Sort by timestamp descending (newest first) client-side
        final sortedReports = List<PoliceReportItem>.from(listResponse.reports)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        print(' Retrieved ${sortedReports.length} police reports');

        return sortedReports;
      } else {
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorResponse = BackendErrorResponse.fromJson(errorData);
          throw Exception('Server error: ${errorResponse.error}');
        } catch (e) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print(' Error getting user reports: $e');
      rethrow;
    }
  }

  /// Validate media file size and type
  static Future<void> _validateMediaFile(File media) async {
    // Check file exists
    if (!await media.exists()) {
      throw Exception('Media file does not exist');
    }

    // Check file size (max 10MB)
    final fileSize = await media.length();
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes

    if (fileSize > maxSize) {
      throw Exception('Media file too large. Maximum size is 10MB');
    }

    // Check file extension
    final extension = media.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'mp4'];

    if (!allowedExtensions.contains(extension)) {
      throw Exception('Invalid file type. Allowed: JPG, PNG, MP4');
    }

    print(
      ' Media file validated: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB, type: $extension',
    );
  }

  /// Test API connectivity
  static Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/emergency/user-reports/');
      final headers = await _getAuthHeaders();

      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      return response.statusCode == 200 ||
          response.statusCode == 401; // 401 means server is reachable
    } catch (e) {
      print(' Connection test failed: $e');
      return false;
    }
  }

  /// Dispose resources
  static void dispose() {
    _client.close();
  }
}
