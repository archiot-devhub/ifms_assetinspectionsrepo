import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/core_modules_screen.dart'; // import your core modules screen
// import your login screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in, go to CoreModulesScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CoreModulesScreen()),
        );
      } else {
        // User not logged in, go to LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // or your brand color
      body: Center(child: Image.asset('assets/Logo Container.png', height: 45)),
    );
  }
}
