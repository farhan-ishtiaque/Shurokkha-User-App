import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; 

const String baseUrl =
    'https://ks-marshall-nsw-controllers.trycloudflare.com';

//HTTP Client with timeout configuration
final http.Client httpClient = http.Client();
const Duration timeoutDuration = Duration(seconds: 50);

Future<void> registerUser({
  required String firstName,
  required String lastName,
  required String username,
  required String email,
  required String phone,
  required String dob,
  required String nidNumber,
  required String address,
  required File nidFront,
  required File selfie,
  required String password,
  required double latitude,
  required double longitude,
}) async {
  try {
    print('Starting registration process...');
    print('Endpoint: $baseUrl/api/users/register/');
    print('Username: $username');
    print('Email: $email');
    print('Phone: $phone');
    print('Address: $address');
    print('Coordinates: $latitude, $longitude');

    final url = Uri.parse('$baseUrl/api/users/register/');

    final request = http.MultipartRequest('POST', url)
      ..fields['first_name'] = firstName
      ..fields['last_name'] = lastName
      ..fields['username'] = username
      ..fields['email'] = email
      ..fields['date_of_birth'] =
          dob // 'YYYY-MM-DD' format
      ..fields['nid_number'] = nidNumber
      ..fields['address'] = address
      ..fields['phone_number'] = phone
      ..fields['password'] = password
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString();

    // Add files
    print('Adding NID front image: ${nidFront.path}');
    request.files.add(
      await http.MultipartFile.fromPath('nid_front_image', nidFront.path),
    );

    print('Adding selfie image: ${selfie.path}');
    request.files.add(
      await http.MultipartFile.fromPath('selfie_image', selfie.path),
    );

    print('Sending registration request...');
    final response = await request.send().timeout(timeoutDuration);

    print('Response status: ${response.statusCode}');

    if (response.statusCode == 201) {
      print('User registered successfully!');
    } else {
      print('Registration failed: ${response.statusCode}');
      final respStr = await response.stream.bytesToString();
      print('Error body: $respStr');
      throw Exception('Registration failed: ${response.statusCode} - $respStr');
    }
  } catch (e) {
    print('Registration error: $e');
    rethrow;
  }
}

// For logging in a user - UPDATED TO USE USERNAME
// Returns login response with token and user data
Future<Map<String, dynamic>> loginUser(
  String username, 
  String password,
) async {
  try {
    final url = Uri.parse(
      '$baseUrl/api/users/login/', 
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username, 
        'password': password,
      }),
    );

    print('Login response status: ${response.statusCode}');
    print('Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Store token and user data for compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('username', data['user']['username'] ?? '');

      return {
        'success': true,
        'token': data['token'],
        'user': data['user'],
        'message': 'Login successful',
      };
    } else {
      return {'success': false, 'error': 'Invalid username or password'};
    }
  } catch (e) {
    print('Login error: $e');
    return {'success': false, 'error': 'Network error: ${e.toString()}'};
  }
}

// For fetching user profile
// Returns the user's profile data if successful, null otherwise.

Future<Map<String, dynamic>?> getUserProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$baseUrl/api/users/profile/'),
    headers: {
      'Authorization': 'Token ${token ?? ''}',
    }, //    FIXED: Use correct Django token format
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    print('Failed to fetch profile: ${response.statusCode}');
    print('Error body: ${response.body}');
    return null;
  }
}

// For logging out a user
// Clears the stored token and username.

Future<void> logoutUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  // Eikhane Shared Preference purapuri clear kore dewa hoise
}

Future<void> updatePersonalInfo({
  required String phone,
  required String email,
  String? password,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final url = Uri.parse('$baseUrl/api/users/update_info/');

  final Map<String, dynamic> body = {'phone_number': phone, 'email': email};

  if (password != null && password.isNotEmpty) {
    body['password'] = password;
  }

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json', 'Authorization': token ?? ''},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    print('Personal info updated successfully!');
  } else {
    print('Failed to update info: ${response.statusCode}');
    print('Response: ${response.body}');
  }
}

Future<Map<String, dynamic>?> getHomeAddress() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return null;

  final response = await http.get(
    Uri.parse('$baseUrl/api/users/get-home-address/'),
    headers: {'Authorization': token},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    print('Error fetching home address: ${response.body}');
    return null;
  }
}

Future<void> setHomeAddress({
  required String address,
  required double latitude,
  required double longitude,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return;

  final response = await http.post(
    Uri.parse('$baseUrl/api/users/set-home-address/'),
    headers: {'Authorization': token},
    body: {
      'full_address': address,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    },
  );

  if (response.statusCode == 200) {
    print("Home address saved.");
  } else {
    print("Failed to save address: ${response.body}");
  }
}

Future<Map<String, dynamic>?> getEmergencyInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return null;

  final response = await http.get(
    Uri.parse('$baseUrl/api/users/get-emergency-info/'),
    headers: {'Authorization': token},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    print('Error fetching emergency info: ${response.body}');
    return null;
  }
}

Future<void> updateEmergencyInfo({
  required String contact1,
  String? contact2,
  String? contact3,
  String? bloodGroup,
  String? healthConditions,
  String? allergies,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return;

  final response = await http.post(
    Uri.parse('$baseUrl/api/users/update-emergency-info/'),
    headers: {'Authorization': token},
    body: {
      'emergency_contact1': contact1,
      'emergency_contact2': contact2 ?? '',
      'emergency_contact3': contact3 ?? '',
      'blood_group': bloodGroup ?? '',
      'health_conditions': healthConditions ?? '',
      'allergies': allergies ?? '',
    },
  );

  if (response.statusCode == 200) {
    print("Emergency info saved.");
  } else {
    print("Failed to save emergency info: ${response.body}");
  }
}

//// For submitting a fire service report
/// Returns true if the report is successfully submitted, false otherwise.

Future<bool> submitFireReport({
  required String description,
  required String address,
  required double latitude,
  required double longitude,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final url = Uri.parse('$baseUrl/api/users/emergency/submit-fire-report/');

  final response = await http.post(
    url,
    headers: {'Authorization': 'Token $token'},
    body: {
      'description': description,
      'address': address,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    },
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return true;
  } else {
    print("Response: ${response.body}");
    return false;
  }
}

// For submitting a medical service report
// Returns true if the report is successfully submitted, false otherwise.

Future<bool> submitMedicalReport({
  required String description,
  required String address,
  required double latitude,
  required double longitude,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  try {
    print('🚑 Submitting simple medical report...');
    print('   Endpoint: $baseUrl/emergency/submit-medical-report/');
    print('🩺 Description: $description');
    print('   Location: $address ($latitude, $longitude)');

    // Submit to Django backend - FIXED to use correct endpoint
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/users/emergency/submit-medical-report/',
      ), //    FIXED: Correct Django endpoint
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'description': description,
        'address': address,
        'latitude': latitude, //    FIXED: Send as number, not string
        'longitude': longitude, //    FIXED: Send as number, not string
      }),
    );

    print('   Response status: ${response.statusCode}');
    print('  Response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   Medical report submitted successfully');
      print('  Report ID: ${data['report_id']}');
      print('🏷️ Category: ${data['category']}');
      print('🤖 AI Advice: ${data['ai_advice'] ?? 'None'}');
      print('  Hospitals notified: ${data['hospitals_notified'] ?? []}');

      //    REMOVED: Django now handles Firestore saving automatically
      // No need to manually save to Firestore - Django does it

      return true;
    } else {
      print("  Medical report failed: ${response.body}");
      return false;
    }
  } catch (e) {
    print('  Error submitting medical report: $e');
    return false;
  }
}

//   POLICE REPORTING MODULE
// Comprehensive police report submission and tracking system

/// Enhanced police report submission with detailed response
/// Returns comprehensive result with report ID, assignment info, and status
Future<Map<String, dynamic>> submitPoliceReport({
  required String description,
  required String address,
  required double latitude,
  required double longitude,
  required bool anonymous,
  File? media,
}) async {
  try {
    print('  Submitting police report...');
    print('   Endpoint: $baseUrl/api/users/emergency/submit-police-report/');
    print('  Description: $description');
    print('   Location: $address ($latitude, $longitude)');
    print('  Anonymous: $anonymous');
    print('  Media attached: ${media != null}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'error': 'No authentication token found'};
    }

    final uri = Uri.parse('$baseUrl/api/users/emergency/submit-police-report/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Token $token'
      ..fields['description'] = description
      ..fields['address'] = address
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['anonymous'] = anonymous.toString();

    if (media != null) {
      request.files.add(await http.MultipartFile.fromPath('media', media.path));
    }

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(responseString);
      print('   Police report submitted successfully');
      print('  Response: $jsonResponse');

      // Sync to Firestore for real-time tracking
      if (jsonResponse['report_id'] != null) {
        await _syncPoliceReportToFirestore(jsonResponse, {
          'description': description,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'anonymous': anonymous,
          'media_attached': media != null,
        });
      }

      return {
        'success': true,
        'report_id': jsonResponse['report_id'],
        'anonymous': jsonResponse['anonymous'] ?? anonymous,
        'assigned_station': jsonResponse['assigned_station'],
        'distance_km': jsonResponse['distance_km'],
        'media_attached': jsonResponse['media_attached'] ?? (media != null),
        'message': jsonResponse['message'],
        'note': jsonResponse['note'],
      };
    } else {
      print('  Police report submission failed: ${response.statusCode}');
      print('  Error response: $responseString');

      final errorResponse = json.decode(responseString);
      return {
        'success': false,
        'error': errorResponse['error'] ?? 'Failed to submit police report',
        'status_code': response.statusCode,
      };
    }
  } catch (e) {
    print('  Exception in police report submission: $e');
    return {'success': false, 'error': 'Network error: $e'};
  }
}

/// Get all police reports for the authenticated user
/// Returns list of police reports with status and assignment information
Future<List<Map<String, dynamic>>> getUserPoliceReports() async {
  try {
    print('  Fetching user police reports...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse(
      '$baseUrl/api/users/emergency/user-reports/?type=police',
    );
    final response = await httpClient
        .get(
          url,
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final reports = List<Map<String, dynamic>>.from(jsonResponse['reports']);

      print('   Found ${reports.length} police reports');
      return reports
          .where((report) => report['report_type'] == 'police')
          .toList();
    } else {
      print('  Failed to fetch police reports: ${response.statusCode}');
      throw Exception('Failed to fetch police reports: ${response.body}');
    }
  } catch (e) {
    print('  Exception in getUserPoliceReports: $e');
    throw Exception('Network error: $e');
  }
}

/// Get detailed status of a specific police report
/// Returns comprehensive report status with officer and station information
Future<Map<String, dynamic>> getPoliceReportStatus(String reportId) async {
  try {
    print('  Fetching police report status for ID: $reportId');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse(
      '$baseUrl/api/users/emergency/police-report-status/$reportId/',
    );
    final response = await httpClient
        .get(
          url,
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      print('   Police report status retrieved successfully');
      return jsonResponse;
    } else {
      print('  Failed to fetch police report status: ${response.statusCode}');
      throw Exception('Failed to fetch report status: ${response.body}');
    }
  } catch (e) {
    print('  Exception in getPoliceReportStatus: $e');
    throw Exception('Network error: $e');
  }
}

/// Sync police report data to Firestore for real-time tracking
Future<void> _syncPoliceReportToFirestore(
  Map<String, dynamic> apiResponse,
  Map<String, dynamic> originalData,
) async {
  try {
    print('  Syncing police report to Firestore...');

    final reportId = apiResponse['report_id'].toString();
    final firestore = FirebaseFirestore.instance;

    final reportDoc = {
      'report_id': reportId,
      'description': originalData['description'],
      'latitude': originalData['latitude'],
      'longitude': originalData['longitude'],
      'address': originalData['address'],
      'anonymous': originalData['anonymous'],
      'media_attached': originalData['media_attached'],
      'assigned_station': apiResponse['assigned_station'],
      'assigned_station_id': apiResponse['assigned_station_id'],
      'distance_km': apiResponse['distance_km'],
      'status': 'pending',
      'operator_status': 'registered',
      'assigned_officer_id': null,
      'assigned_officer_name': null,
      'timestamp': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'user_rating': null, // Will be populated by backend
    };

    await firestore.collection('police_reports').doc(reportId).set(reportDoc);

    print('   Police report synced to Firestore successfully');
  } catch (e) {
    print('  Failed to sync to Firestore (non-critical): $e');
    // Don't throw here as this is not critical for report submission
  }
}

//   Medical Emergency Functions

/// Submit medical emergency report with AI classification - FIXED FOR JSON
Future<Map<String, dynamic>> submitMedicalEmergencyReport({
  required String description,
  required double latitude,
  required double longitude,
  String? address,
}) async {
  try {
    print('🚑 Submitting medical emergency report...');
    print('   Endpoint: $baseUrl/api/users/emergency/submit-medical-report/');
    print('🩺 Description: $description');
    print('   Location: $address ($latitude, $longitude)');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse(
      '$baseUrl/api/users/emergency/submit-medical-report/',
    ); //    FIXED: Correct endpoint with proper path

    final response = await httpClient
        .post(
          url,
          headers: {
            'Content-Type': 'application/json', //    FIXED: JSON content type
            'Authorization': 'Token $token', //    CORRECT: Django token format
          },
          body: jsonEncode({
            'description': description, //    CORRECT: Exact field names
            'latitude': latitude, //    CORRECT: Double type as required
            'longitude': longitude, //    CORRECT: Double type as required
            'address': address ?? '', //    CORRECT: String field as required
          }),
        )
        .timeout(timeoutDuration);

    print('   Response status: ${response.statusCode}');
    print('  Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      //    RETURN DJANGO'S ACTUAL RESPONSE FORMAT
      return {
        'success': true,
        'message':
            data['message'], // Django field: "Medical report submitted successfully"
        'report_id': data['report_id'], // Django field: Report ID
        'category':
            data['category'], // Django field: "ordinary/moderate/serious"
        'ai_advice': data['ai_advice'], // Django field: AI advice from DeepSeek
        'status': data['status'] ?? 'pending', // Django field: Report status
        'auto_completed':
            data['auto_completed'] ??
            false, // Django field: Auto-completion flag
        'hospitals_notified':
            data['hospitals_notified'] ?? [], // Django field: List of hospitals
        'hospitals_count':
            data['hospitals_count'] ?? 0, // Django field: Number of hospitals
        'operator_notified':
            data['operator_notified'] ??
            false, // Django field: Operator notification
        'escalation_scheduled':
            data['escalation_scheduled'] ??
            false, // Django field: Escalation flag
        'escalation_time_minutes':
            data['escalation_time_minutes'] ??
            0, // Django field: Escalation time
        'action_required':
            data['action_required'] ??
            true, // Django field: Action required flag
        'advice_message':
            data['advice_message'] ?? '', // Django field: Advice message
        'escalation_info':
            data['escalation_info'] ??
            {}, // Django field: Escalation information
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 'Failed to submit medical report',
      };
    }
  } catch (e) {
    print('  Error submitting medical report: $e');
    return {'success': false, 'error': 'Network error: ${e.toString()}'};
  }
}

/// Get medical report status - IMPLEMENTED TO MATCH DJANGO DOCS
Future<Map<String, dynamic>?> getMedicalReportStatus(String reportId) async {
  try {
    print('  Getting medical report status for ID: $reportId');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse(
      '$baseUrl/emergency/report-status/$reportId/',
    ); //    DJANGO ENDPOINT

    final response = await httpClient
        .get(url, headers: {'Authorization': 'Token $token'})
        .timeout(timeoutDuration);

    print('   Report status response: ${response.statusCode}');
    print('  Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'report_id': data['report_id'],
        'status': data['status'],
        'category': data['category'],
        'ai_advice': data['ai_advice'],
        'description': data['description'],
        'timestamp': data['timestamp'],
        'location': data['location'],
        'assigned_hospital': data['assigned_hospital'],
        'assigned_driver': data['assigned_driver'],
      };
    } else if (response.statusCode == 404) {
      return {'success': false, 'error': 'Report not found'};
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 'Failed to get report status',
      };
    }
  } catch (e) {
    print('  Error getting medical report status: $e');
    //    FALLBACK: Try Firestore if Django endpoint fails (for backwards compatibility)
    return await _getMedicalReportStatusFromFirestore(reportId);
  }
}

/// FALLBACK: Get medical report status from Firestore (backwards compatibility)
Future<Map<String, dynamic>?> _getMedicalReportStatusFromFirestore(
  String reportId,
) async {
  try {
    print(
      '  FALLBACK: Getting medical report status from Firestore for ID: $reportId',
    );

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('medical_reports')
        .doc(reportId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'success': true,
        'report_id': data['report_id'],
        'status': data['status'],
        'category': data['category'],
        'ai_advice': data['ai_advice'],
        'description': data['description'],
        'timestamp': data['timestamp'],
        'location': {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'address': data['address'],
        },
        'assigned_hospital': data['assigned_hospital'],
        'assigned_driver': data['assigned_driver'],
      };
    }
    return {'success': false, 'error': 'Report not found in Firestore'};
  } catch (e) {
    print('  Error getting medical report status from Firestore: $e');
    return {
      'success': false,
      'error': 'Failed to get report status: ${e.toString()}',
    };
  }
}

/// Get all user's medical reports - IMPLEMENTED TO MATCH DJANGO DOCS
Future<Map<String, dynamic>> getUserMedicalReports() async {
  try {
    print('  Getting user medical reports...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse(
      '$baseUrl/emergency/user-reports/',
    ); //    DJANGO ENDPOINT

    final response = await httpClient
        .get(url, headers: {'Authorization': 'Token $token'})
        .timeout(timeoutDuration);

    print('   User reports response: ${response.statusCode}');
    print('  Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'reports': data['reports'],
        'count': data['count'] ?? 0,
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 'Failed to get user reports',
        'reports': [],
        'count': 0,
      };
    }
  } catch (e) {
    print('  Error getting user medical reports: $e');
    //    FALLBACK: Try Firestore if Django endpoint fails (for backwards compatibility)
    return await _getUserMedicalReportsFromFirestore();
  }
}

/// FALLBACK: Get user's medical reports from Firestore (backwards compatibility)
Future<Map<String, dynamic>> _getUserMedicalReportsFromFirestore() async {
  try {
    print('  FALLBACK: Getting user medical reports from Firestore...');

    final userProfile = await getUserProfile();

    if (userProfile == null || userProfile['id'] == null) {
      print('  No user profile found');
      return {
        'success': false,
        'error': 'No user profile found',
        'reports': [],
        'count': 0,
      };
    }

    final userId = userProfile['id'];

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('medical_reports')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    final reports = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    return {'success': true, 'reports': reports, 'count': reports.length};
  } catch (e) {
    print('  Error getting user medical reports from Firestore: $e');
    return {
      'success': false,
      'error': 'Failed to get reports: ${e.toString()}',
      'reports': [],
      'count': 0,
    };
  }
}

/// Update medical report status - IMPLEMENTED TO MATCH DJANGO DOCS
Future<Map<String, dynamic>> updateMedicalReportStatus({
  required String reportId,
  required String status, // pending/accepted/completed
}) async {
  try {
    print('  Updating medical report status: $reportId -> $status');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse(
      '$baseUrl/emergency/update-status/$reportId/',
    ); //    DJANGO ENDPOINT

    final response = await httpClient
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: jsonEncode({'status': status}),
        )
        .timeout(timeoutDuration);

    print('   Update status response: ${response.statusCode}');
    print('  Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? true,
        'report_id': data['report_id'],
        'new_status': data['new_status'],
        'message': 'Status updated successfully',
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 'Failed to update status',
      };
    }
  } catch (e) {
    print('  Error updating medical report status: $e');
    return {'success': false, 'error': 'Network error: ${e.toString()}'};
  }
}
