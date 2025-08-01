import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'bulk_upload_asset_screen.dart';
import 'asset_register_screen.dart';
import '../core/core_modules_screen.dart';
import 'asset_detail_screen.dart';
import 'asset_details_qr_scanner_screen.dart'; // Your QR scanner screen

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
            // Navigate back to Core Modules screen
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
            // Asset list removed as per your request
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
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
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
              label: 'Under Maintenance',
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
              icon: Icons.trending_down,
              color: Colors.purple,
            ),
            const SizedBox(width: 0),
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
              // Navigate to your QR scanner screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssetScanScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.upload_file),
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
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('AssetRegister')
              .orderBy('modifiedTime', descending: true)
              .limit(10)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text("No recent activities."),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0, left: 2),
              child: Text(
                "Recent Activity",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final assetID = data['assetID'] ?? 'Unknown';
              String activityMsg = '';
              if ((data['condition_changed'] ?? false) == true) {
                // Remove quotes for Working/Active
                String cond = (data['condition'] ?? '').toString();
                if (cond.toLowerCase() == 'working') cond = 'Working';
                if (cond.toLowerCase() == 'active') cond = 'Active';
                activityMsg = "Condition changed to $cond";
              } else if ((data['status_changed'] ?? false) == true) {
                String status = (data['status'] ?? '').toString();
                if (status.toLowerCase() == 'working') status = 'Working';
                if (status.toLowerCase() == 'active') status = 'Active';
                activityMsg = "Status changed to $status";
              } else if (data['desc'] != null) {
                activityMsg = data['desc'];
              } else {
                String cond = (data['condition'] ?? '').toString();
                String status = (data['status'] ?? '').toString();
                activityMsg = 'Condition: $cond, Status: $status';
              }

              final Timestamp? modifiedTs = data['modifiedTime'] as Timestamp?;
              final dateStr =
                  modifiedTs != null ? _prettyTimeAgo(modifiedTs.toDate()) : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white, // Card background color
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.06),
                      spreadRadius: 0.5,
                      blurRadius: 5,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 14,
                  ),
                  title: Text(
                    assetID,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      activityMsg,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  trailing: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // Utility: Human friendly time difference
  static String _prettyTimeAgo(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Few mins ago'; // instead of 'Just now'
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('yyyy-MM-dd').format(time);
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
          icon: Icon(Icons.list_alt),
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
      },
    );
  }
}
