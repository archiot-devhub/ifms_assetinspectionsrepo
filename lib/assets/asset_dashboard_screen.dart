import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'bulk_upload_asset_screen.dart';
import 'asset_register_screen.dart';
import '../core/core_modules_screen.dart';

class AssetDashboardScreen extends StatelessWidget {
  const AssetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Replace with CoreModulesScreen (use pushReplacement to prevent stacking)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CoreModulesScreen()),
            );
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: const _DashboardBody(),
      bottomNavigationBar: const _AssetDashboardBottomBar(currentIndex: 0),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('AssetRegister').snapshots(),
      builder: (context, snapshot) {
        int totalAssets = 0;
        int working = 0;
        int breakdown = 0;
        int underMaintenance = 0;
        int degrading = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalAssets = docs.length;
          for (final doc in docs) {
            final cond = (doc['condition'] as String?)?.toLowerCase() ?? '';
            if (cond == 'working') {
              working++;
            } else if (cond == 'breakdown') {
              breakdown++;
            } else if (cond == 'undermaintenance' ||
                cond == 'under maintenance') {
              underMaintenance++;
            } else if (cond == 'degrading') {
              degrading++;
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AssetStatsCard(
              totalAssets: totalAssets,
              working: working,
              breakdown: breakdown,
              underMaintenance: underMaintenance,
              degrading: degrading,
            ),
            const SizedBox(height: 16),
            const _QuickActions(),
            const SizedBox(height: 16),
            const _RecentActivityPlaceholder(),
          ],
        );
      },
    );
  }
}

class _AssetStatsCard extends StatelessWidget {
  final int totalAssets;
  final int working;
  final int breakdown;
  final int underMaintenance;
  final int degrading;

  const _AssetStatsCard({
    required this.totalAssets,
    required this.working,
    required this.breakdown,
    required this.underMaintenance,
    required this.degrading,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildStatBox({
      required String label,
      required int value,
      required IconData icon,
      required Color color,
    }) {
      return Expanded(
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(label, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            buildStatBox(
              label: 'Total Assets',
              value: totalAssets,
              icon: Icons.devices_other_outlined,
              color: Colors.blue,
            ),
            buildStatBox(
              label: 'Working',
              value: working,
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ],
        ),
        Row(
          children: [
            buildStatBox(
              label: 'Breakdown',
              value: breakdown,
              icon: Icons.warning_amber_outlined,
              color: Colors.red,
            ),
            buildStatBox(
              label: 'Undermaintenance',
              value: underMaintenance,
              icon: Icons.build_circle_outlined,
              color: Colors.orange,
            ),
          ],
        ),
        Row(
          children: [
            buildStatBox(
              label: 'Degrading',
              value: degrading,
              icon: Icons.trending_down_outlined,
              color: Colors.purple,
            ),
            const SizedBox(width: 0), // To keep layout even
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan Asset QR'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan Asset QR coming soon!')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import Via Excel'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BulkUploadAssetScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentActivityPlaceholder extends StatelessWidget {
  const _RecentActivityPlaceholder();

  @override
  Widget build(BuildContext context) {
    final activities = [
      "ID023 Chiller status changed",
      "ID024 Compressor malfunction detected",
      "ID027 System maintenance scheduled",
      "ID028 Filter replacement needed",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Recent Activity",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...activities.map(
          (activity) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(activity),
              subtitle: const Text("Few mins ago"),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetDashboardBottomBar extends StatelessWidget {
  final int currentIndex;

  const _AssetDashboardBottomBar({this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_rounded),
          label: 'All Assets',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.import_export),
          label: 'Asset Transfer',
        ),
      ],
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssetRegisterScreen()),
          );
        } else if (index == 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset Transfer coming soon!')),
          );
        }
        // index == 0 is Dashboard; do nothing or maybe refresh
      },
    );
  }
}
