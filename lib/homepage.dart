import 'package:flutter/material.dart';
import 'package:shurokkha_app/Settings/change_personal_info.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  static final _cardItems = [
    {'title': 'Police', 'image': 'assets/images/police_logo.png'},
    {'title': 'FireService', 'image': 'assets/images/firedept_logo.png'},
    {'title': 'Medical', 'image': 'assets/images/medical_logo.png'},
    {'title': 'Contact Operator', 'image': 'assets/images/operator.png'},
  ];

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Homepage',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        titleSpacing: 10,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                color: Color.fromARGB(255, 29, 56, 114),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage(
                      'assets/images/profile_pic.jpeg',
                    ),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Username: farhan123',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Name: Farhan',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          'Email: farhan@gmail.com',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
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
                        builder: (context) => ChangePersonalInfoScreen(
                          currentPhone: '01700000000',
                          currentEmail: 'farhan@gmail.com',
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Update Emergency Info'),
                  onTap: () => debugPrint('Update Emergency Info tapped'),
                ),
                ListTile(
                  title: const Text('Set Home Address'),
                  onTap: () => debugPrint('Set Home Address tapped'),
                ),
                ListTile(
                  title: const Text('Privacy & Security'),
                  onTap: () => debugPrint('Privacy & Security tapped'),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                debugPrint('Logout tapped');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => debugPrint('Floating Action Button Pressed'),
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
        children: List.generate(Homepage._cardItems.length, (index) {
          final item = Homepage._cardItems[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => debugPrint('Tapped: ${item['title']}'),
            child: Card(
              color: const Color.fromARGB(255, 255, 215, 230),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    item['image']!,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
