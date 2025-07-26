import 'package:flutter/material.dart';
import 'package:shurokkha_app/homepage.dart';
import 'package:shurokkha_app/register_page.dart';
import 'package:shurokkha_app/login_page.dart';

main() {
  var app =
      const MyApp(); //Constant because these parts are fixed and don't need any changing
  runApp(app);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme(
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
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,

      //home: RegisterPage(),
      home: LoginPage(),
      //home: Homepage(),
    );
  }
}
