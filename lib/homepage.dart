import 'package:flutter/material.dart';
import 'package:shurokkha_app/Settings/change_personal_info.dart';
import 'package:shurokkha_app/Settings/update_emergency_info.dart';
import 'package:shurokkha_app/Settings/set_home_address.dart';
import 'package:shurokkha_app/Settings/profile_page.dart';
import 'package:shurokkha_app/login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';
import 'package:shurokkha_app/Homepage_cards/fire_service_form.dart';
import 'package:shurokkha_app/Homepage_cards/cases_screen.dart';
import 'package:shurokkha_app/Homepage_cards/emergency_button.dart';
import 'package:shurokkha_app/Homepage_cards/medical_service_form.dart';
import 'package:shurokkha_app/Homepage_cards/police_service_form.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  static final _cardItems = [
    {'title': 'Police', 'image': 'assets/images/police_logo.png'},
    {'title': 'FireService', 'image': 'assets/images/firedept_logo.png'},
    {'title': 'Medical', 'image': 'assets/images/medical_logo.png'},
    {'title': 'Contact Operator', 'image': 'assets/images/operator.png'},
    {'title': 'Cases', 'image': 'assets/images/active_cases.png'},
  ];

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool isSettingsExpanded = false;
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

  void _callOperator() async {
    final Uri url = Uri(scheme: 'tel', path: '999');
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while launching dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SHUROKKHA',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        titleSpacing: 10,
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 166, 38, 80),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 138, 94, 135),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        _profile != null && _profile!['selfie_image'] != null
                        ? NetworkImage('$baseUrl${_profile!['selfie_image']}')
                        : const AssetImage('assets/profile_pic.png')
                              as ImageProvider,
                  ),

                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _loading || _profile == null
                          ? [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ]
                          : [
                              Text(
                                '${_profile!['username'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                '${_profile!['first_name'] ?? ''} ${_profile!['last_name'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                '${_profile!['email'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_2, color: Colors.black),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text('Settings'),
              trailing: Icon(
                isSettingsExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.black,
              ),
              onExpansionChanged: (expanded) {
                setState(() => isSettingsExpanded = expanded);
              },
              children: [
                ListTile(
                  title: const Text('Change Personal Info'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePersonalInfoScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Update Emergency Info'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateEmergencyInfoScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Set Home Address'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetHomeAddressScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text('Logout'),
              onTap: () => _performLogout(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tappedEmergencyButton(context),
        backgroundColor: const Color.fromARGB(255, 255, 0, 85),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: const Icon(Icons.add_alert_outlined),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: const EdgeInsets.all(16),
        childAspectRatio: 1.1, // Increase height to accommodate content
        children: List.generate(Homepage._cardItems.length, (index) {
          final item = Homepage._cardItems[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              debugPrint('Tapped: ${item['title']}');
              if (item['title'] == 'Contact Operator') {
                _callOperator();
              } else if (item['title'] == 'Police') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PoliceServiceRequestScreen(),
                  ),
                );
              } else if (item['title'] == 'FireService') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FireServiceRequestScreen(),
                  ),
                );
              } else if (item['title'] == 'Medical') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicalServiceRequestScreen(),
                  ),
                );
              } else if (item['title'] == 'Cases') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CasesScreen()),
                );
              }
            },
            child: Card(
              color: const Color.fromARGB(255, 255, 215, 230),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Image.asset(
                        item['image']!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

void _performLogout(BuildContext context) async {
  await logoutUser();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (Route<dynamic> route) => false,
  );
}

void _tappedEmergencyButton(BuildContext context) {
  debugPrint('Emergency Button Tapped');
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EmergencyButtonPage()),
  );
}
