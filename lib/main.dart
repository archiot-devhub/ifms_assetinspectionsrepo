import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 👈 Add this import

import 'package:profiminspectionapp/screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 Use correct config
  );
  runApp(const ProfimInspectionApp());
}

class ProfimInspectionApp extends StatelessWidget {
  const ProfimInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profim Inspection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // 🔲 All screens white background
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
