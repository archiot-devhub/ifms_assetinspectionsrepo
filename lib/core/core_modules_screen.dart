import 'package:flutter/material.dart';
import '../maintenance/maintenance_home_screen.dart';
import '../inspections/module_selection_screen.dart';
import '../assets/asset_register_screen.dart';
import '../maintenance/maintenance_schedule_screen.dart';

class CoreModulesScreen extends StatelessWidget {
  const CoreModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Assets',
        'icon': Icons.inventory_2_outlined,
        'screen': const AssetRegisterScreen(),
      },
      {
        'title': 'Maintenance',
        'icon': Icons.build_circle_outlined,
        'screen': const MaintenanceScheduleScreen(),
      },
      {
        'title': 'Inspections',
        'icon': Icons.assignment_turned_in_outlined,
        'screen': const ModuleSelectionScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Core Modules'),
        automaticallyImplyLeading: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
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
