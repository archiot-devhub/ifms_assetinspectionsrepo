import 'package:flutter/material.dart';
import '../screens/inspection_list_screen.dart';
import '../screens/general_inspection_list_screen.dart';
import '../core/core_modules_screen.dart';

class ModuleSelectionScreen extends StatelessWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Asset Inspection',
        'icon': Icons.qr_code_scanner,
        'screen': const InspectionListScreen(),
        'enabled': true,
      },
      {
        'title': 'General Inspection',
        'icon': Icons.list_alt,
        'screen': const GeneralInspectionListScreen(),
        'enabled': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Inspection Module'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Core Modules',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CoreModulesScreen()),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004EFF), Color(0xFF002F99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            double horizontalPadding = 20;
            double verticalPadding = 36;
            double crossSpacing = 20;
            double mainSpacing = 20;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: modules.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1, // Square/medium card, adjust as needed
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
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: Icon(
                              module['icon'] as IconData,
                              size: 40, // Match your core module icon size
                              color: const Color(0xFF004EFF),
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
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
