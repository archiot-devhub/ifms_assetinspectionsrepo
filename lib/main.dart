import 'package:flutter/material.dart';
import 'screens/inspection_list_screen.dart';

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
      home: const InspectionListScreen(),
    );
  }
}
