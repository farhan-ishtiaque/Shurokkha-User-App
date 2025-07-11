import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  static final _cardItems = [
    {'title': 'Police', 'image': 'assets/images/police_logo.png'},
    {'title': 'FireService', 'image': 'assets/images/firedept_logo.png'},
    {'title': 'Medical', 'image': 'assets/images/medical_logo.png'},
    {'title': 'Logout', 'image': 'assets/images/shurokkha_logo.png'},
  ];

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
        elevation: 6,
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
              decoration: const BoxDecoration(color: Colors.pink),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ────────────── Profile Picture ──────────────
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage(
                      'assets/images/profile_pic.png',
                    ), // or NetworkImage(...)
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 16),

                  // ────────────── User Info ──────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Username: johndoe123',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Name: John Doe',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          'Email: john@example.com',
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
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add logout functionality here
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action here
          debugPrint('Floating Action Button Pressed');
        },
        child: const Icon(Icons.add_alert_outlined),
        backgroundColor: const Color.fromARGB(255, 255, 0, 85),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: const EdgeInsets.all(16),
        children: List.generate(_cardItems.length, (index) {
          final item = _cardItems[index];
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
