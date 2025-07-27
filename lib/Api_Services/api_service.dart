import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


const String baseUrl = 'https://morris-klein-toward-building.trycloudflare.com';

Future<void> registerUser({
  required String firstName,
  required String lastName,
  required String username,
  required String email,
  required String phone,
  required String dob,
  required String nidNumber,
  required String father,
  required String mother,
  required String address,
  required File nidFront,
  required File nidBack,
  required File selfie,
  required String password,
}) async {
  final url = Uri.parse(
    '$baseUrl/api/users/register/',
  );


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
    ..fields['Father_name'] = father
    ..fields['Mother_name'] = mother
    ..fields['address'] = address
    ..fields['phone_number'] = phone
    ..fields['password'] = password
    ..files.add(
      await http.MultipartFile.fromPath('nid_front_image', nidFront.path),
    )
    ..files.add(
      await http.MultipartFile.fromPath('nid_back_image', nidBack.path),
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
    body: jsonEncode({
      'username': username,
      'password': password,
    }),
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
    headers: {
      'Authorization': token ?? '',
    },
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
  await prefs.remove('token');
  await prefs.remove('username');
  // Eikhane Logout er porer action set hobe
}
