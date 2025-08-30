import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shurokkha_app/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase, ignore duplicate app error
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains(
      'A Firebase App named "[DEFAULT]" already exists',
    )) {
      // Already initialized, safe to continue
    } else {
      rethrow;
    }
  }

  // ✅ Handle Flutter errors gracefully
  FlutterError.onError = (FlutterErrorDetails details) {
    // Handle UI overflow errors without crashing
    if (details.exception.toString().contains('RenderFlex overflowed')) {
      debugPrint('UI Overflow Error (handled): ${details.exception}');
      return;
    }

    // Handle OpenGL/graphics context errors
    if (details.exception.toString().contains('egl') ||
        details.exception.toString().contains('OpenGL') ||
        details.exception.toString().contains('renderer')) {
      debugPrint('Graphics Error (handled): ${details.exception}');
      return;
    }

    // Log other errors but don't crash
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.pink,
          onPrimary: Colors.black,
          secondary: Colors.orangeAccent,
          onSecondary: Colors.black,
          error: Colors.redAccent,
          onError: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,

      //home: Homepage(), // ✅ Skip login for testing
      home: LoginPage(),
      //home: EmergencyButtonPage(),
      //home: const ActiveCasesPage(), // Testing active cases page with user_id query
      //home: Homepage(),
      //home: const ProfilePage(),
      //home: FireServiceRequestScreen(),
      //home: MedicalServiceRequestScreen(),
      //home: PoliceServiceRequestScreen(),
      //home: SetHomeAddressScreen(),
      //home: UpdateEmergencyInfoScreen(),
      //home: ChangePersonalInfoScreen(currentPhone: '01700000000', currentEmail: 'farhan@gmail.com'),
    );
  }
}
