import 'package:flutter/material.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await getUserProfile();
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Widget _buildField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : '')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        shadowColor: Colors.pinkAccent.shade100,
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const Center(child: Text('Failed to load profile'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _profile!['selfie_image'] != null
                          ? NetworkImage('$baseUrl${_profile!['selfie_image']}')
                          : const AssetImage('assets/placeholder.png')
                                as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Personal Info
                  _buildField('First Name', _profile!['first_name']),
                  _buildField('Last Name', _profile!['last_name']),
                  _buildField('Username', _profile!['username']),
                  _buildField('Email', _profile!['email']),
                  _buildField('Phone', _profile!['phone_number']),
                  _buildField('Date of Birth', _profile!['date_of_birth']),
                  _buildField('NID Number', _profile!['nid_number']),
                  _buildField('Address', _profile!['address']),
                  _buildField('Rating', _profile!['rating']?.toString()),

                  // Emergency Contacts & Health Info
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    'Emergency & Health Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildField(
                    'Emergency Contact 1',
                    _profile!['emergency_contact1'],
                  ),
                  _buildField(
                    'Emergency Contact 2',
                    _profile!['emergency_contact2'],
                  ),
                  _buildField(
                    'Emergency Contact 3',
                    _profile!['emergency_contact3'],
                  ),
                  _buildField('Blood Group', _profile!['blood_group']),
                  _buildField(
                    'Health Conditions',
                    _profile!['health_conditions'],
                  ),
                  _buildField('Allergies', _profile!['allergies']),
                ],
              ),
            ),
    );
  }
}
