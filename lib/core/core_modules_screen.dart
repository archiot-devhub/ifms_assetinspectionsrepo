import 'package:flutter/material.dart';
import '../inspections/module_selection_screen.dart';
import '../assets/asset_register_screen.dart';
import '../maintenance/maintenance_schedule_screen.dart';
import '../assets/asset_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../maintenance/maintenance_dashboard_screen.dart';

class CoreModulesScreen extends StatelessWidget {
  const CoreModulesScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Asset Management',
        'icon': Icons.settings_outlined,
        'screen': const AssetDashboardScreen(),
        'enabled': true,
      },
      {
        'title': 'Maintenance Management',
        'icon': Icons.build_outlined,
        'screen': const MaintenanceDashboardScreen(),
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
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004EFF), Color(0xFF002F99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount =
                constraints.maxWidth > constraints.maxHeight ? 4 : 2;
            int rowCount = (modules.length / crossAxisCount).ceil();
            double horizontalPadding = 20;
            double verticalPadding = 20;
            double crossSpacing = 20;
            double mainSpacing = 20;

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
                physics: const NeverScrollableScrollPhysics(),
                itemCount: modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: mainSpacing,
                  crossAxisSpacing: crossSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  final enabled = module['enabled'] == true;

                  return GestureDetector(
                    onTap: () {
                      if (enabled) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => module['screen'] as Widget,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 25.0),
                            child: Icon(
                              module['icon'] as IconData,
                              size: 48,
                              color: const Color(0xFF004EFF),
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              child: Text(
                                module['title'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width < 400
                                          ? 11
                                          : 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),
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
