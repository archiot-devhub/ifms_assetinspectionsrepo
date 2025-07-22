import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/inspection_list_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/checkpoint_screen.dart';

void main() {
  runApp(const ProfimInspectionApp());
}

class ProfimInspectionApp extends StatelessWidget {
  const ProfimInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profim Inspection App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // 👈 Set Login as initial screen
    );
  }
}
