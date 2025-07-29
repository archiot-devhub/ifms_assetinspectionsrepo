import 'package:flutter/material.dart';
import '../inspections/module_selection_screen.dart';
import '../assets/asset_register_screen.dart';
import '../maintenance/maintenance_schedule_screen.dart';
import '../assets/asset_dashboard_screen.dart';

class CoreModulesScreen extends StatelessWidget {
  const CoreModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Asset Management',
        'icon': Icons.settings,
        'screen': const AssetDashboardScreen(),
        'enabled': true,
      },
      {
        'title': 'Maintenance Management',
        'icon': Icons.build,
        'screen': const MaintenanceScheduleScreen(),
        'enabled': true,
      },
      {
        'title': 'Inspection Management',
        'icon': Icons.article_outlined,
        'screen': const ModuleSelectionScreen(),
        'enabled': true,
      },
      {
        'title': 'Vendor Management',
        'icon': Icons.business_center_outlined,
        'enabled': false,
      },
      {
        'title': 'Tenant Management',
        'icon': Icons.people_outline,
        'enabled': false,
      },
      {
        'title': 'Service Requests',
        'icon': Icons.plumbing_outlined,
        'enabled': false,
      },
      {
        'title': 'Sustainability Management',
        'icon': Icons.public,
        'enabled': false,
      },
      {
        'title': 'Document Management',
        'icon': Icons.insert_drive_file_outlined,
        'enabled': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Force the grid to always show 2 rows and 4 columns (8 items in all)
            int crossAxisCount =
                constraints.maxWidth > constraints.maxHeight
                    ? 4
                    : 2; // landscape vs portrait
            int rowCount = (modules.length / crossAxisCount).ceil();

            // Calculate spacing and size so ALL tiles fit on the screen
            double horizontalPadding = 10;
            double verticalPadding = 10;
            double crossSpacing = 10;
            double mainSpacing = 10;

            double availableWidth =
                constraints.maxWidth -
                2 * horizontalPadding -
                (crossAxisCount - 1) * crossSpacing;
            double availableHeight =
                constraints.maxHeight -
                2 * verticalPadding -
                (rowCount - 1) * mainSpacing;

            double itemWidth = availableWidth / crossAxisCount;
            double itemHeight = availableHeight / rowCount;

            double childAspectRatio = itemWidth / itemHeight;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: GridView.builder(
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent scrolling
                itemCount: modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: mainSpacing,
                  crossAxisSpacing: crossSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return GestureDetector(
                    onTap:
                        module['enabled'] == true
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => module['screen'] as Widget,
                                ),
                              );
                            }
                            : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              module['enabled'] == true
                                  ? Colors.blueAccent
                                  : Colors.grey.shade300,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            module['icon'] as IconData,
                            size: 32,
                            color:
                                module['enabled'] == true
                                    ? Colors.blue
                                    : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            module['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  module['enabled'] == true
                                      ? Colors.black
                                      : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
