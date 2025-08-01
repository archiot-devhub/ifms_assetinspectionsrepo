import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'bulk_upload_asset_screen.dart';
import 'asset_register_screen.dart';
import '../core/core_modules_screen.dart';
import 'asset_detail_screen.dart';
import 'asset_details_qr_scanner_screen.dart';

class AssetDashboardScreen extends StatelessWidget {
  const AssetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF004EFF),
                Color(0xFF002F99),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Asset Management',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CoreModulesScreen()),
                );
              },
            ),
            automaticallyImplyLeading: false,
          ),
        ),
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
      stream: FirebaseFirestore.instance.collection('AssetRegister').snapshots(),
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
            } else if (cond == 'undermaintenance' || cond == 'under maintenance') {
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
                    ),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    const iconColor = Color(0xFF004EFF); // Icon color in hex
    final textColor = Colors.grey.shade800; // Grey text

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton.icon(
              icon: Icon(Icons.qr_code_scanner_rounded, color: iconColor,size: 24),
              label: Text(
                'Scan Asset QR',
                style: TextStyle(color: textColor),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssetScanScreen()),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton.icon(
              icon: Icon(Icons.upload_file_outlined, color: iconColor, size: 24),
              label: Text(
                'Import Via Excel',
                style: TextStyle(color: textColor),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BulkUploadAssetScreen()),
                );
              },
            ),
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
      stream: FirebaseFirestore.instance
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
              final dateStr = modifiedTs != null ? _prettyTimeAgo(modifiedTs.toDate()) : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                  title: Text(
                    assetID,
                    style: const TextStyle(
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

  static String _prettyTimeAgo(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Few mins ago';
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
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF004EFF),
      unselectedItemColor: Colors.black,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
