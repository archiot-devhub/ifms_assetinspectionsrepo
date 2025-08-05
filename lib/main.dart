import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 👈 Add this import

import 'package:profiminspectionapp/screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart'; // auto-generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
<<<<<<< HEAD
    options: DefaultFirebaseOptions.currentPlatform, // 👈 Use correct config
  );
=======
    options: DefaultFirebaseOptions.currentPlatform,
  ); // ✅ Initialize Firebase
>>>>>>> 6f2760a (Version 21: Mainteancne dashboard and asset timeline screens are added)
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
<<<<<<< HEAD
        scaffoldBackgroundColor: Colors.white, // 🔲 All screens white background
=======
        scaffoldBackgroundColor:
            Colors.white, // 🔲 Sets all pages' background to white
>>>>>>> 6f2760a (Version 21: Mainteancne dashboard and asset timeline screens are added)
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
