import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String baseUrl = 'https://guided-booking-incl-exactly.trycloudflare.com';

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
}) async {
  final url = Uri.parse('$baseUrl/api/users/register/');

  // For registering a new user
  // The function takes user details and uploads them to the server.

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
    ..files.add(
      await http.MultipartFile.fromPath('nid_front_image', nidFront.path),
    )
    ..files.add(await http.MultipartFile.fromPath('selfie_image', selfie.path));

  final response = await request.send();

  if (response.statusCode == 201) {
    print('User registered successfully!');
  } else {
    print('Registration failed: ${response.statusCode}');
    final respStr = await response.stream.bytesToString();
    print('Error body: $respStr');
  }
}

// For logging in a user
// Returns true if login is successful, false otherwise.

Future<bool> loginUser(String username, String password) async {
  final url = Uri.parse('$baseUrl/api/users/login/');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final token = data['token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', data['user']['username']);

    return true;
  } else {
    print('Login failed: ${response.body}');
    return false;
  }
}

// For fetching user profile
// Returns the user's profile data if successful, null otherwise.

Future<Map<String, dynamic>?> getUserProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$baseUrl/api/users/profile/'),
    headers: {'Authorization': token ?? ''},
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

  final url = Uri.parse('$baseUrl/api/users/fire_service/submit-fire-report/');

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
