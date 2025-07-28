import 'package:flutter/material.dart';
import '../screens/inspection_list_screen.dart'; // Your existing Asset Inspection screen
import '../screens/general_inspection_list_screen.dart'; // To be created

class ModuleSelectionScreen extends StatelessWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inspectionModules = [
      {
        'title': 'Asset Inspection',
        'icon': Icons.qr_code_scanner,
        'screen': const InspectionListScreen(),
      },
      {
        'title': 'General Inspection',
        'icon': Icons.list_alt,
        'screen': const GeneralInspectionListScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Inspection Module')),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: inspectionModules.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemBuilder: (context, index) {
          final module = inspectionModules[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => module['screen'] as Widget),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    module['icon'] as IconData,
                    size: 40,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    module['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
