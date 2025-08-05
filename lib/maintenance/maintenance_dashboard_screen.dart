import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../maintenance/maintenance_schedule_screen.dart';
import '../maintenance/Breakdown/breakdown_maintenance_screen.dart';

const Color appBlue = Color(0xFF004EFF);

class MaintenanceDashboardScreen extends StatefulWidget {
  const MaintenanceDashboardScreen({Key? key}) : super(key: key);

  @override
  _MaintenanceDashboardScreenState createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState
    extends State<MaintenanceDashboardScreen> {
  List<Map<String, dynamic>> recentActivity = [];
  bool loading = true;
  int ppmScheduledCount = 0;
  int ppmCompletedCount = 0;
  int ppmDelayedCount = 0;
  int bdPendingCount = 0;
  int bdAssignedCount = 0;
  int bdResolvedCount = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);

    // PPM Maintenance
    final ppmSnap =
        await FirebaseFirestore.instance
            .collection('MaintenanceSchedules')
            .get();
    final ppmDocs = ppmSnap.docs;
    int scheduled = 0, completed = 0, delayed = 0;
    DateTime now = DateTime.now();
    for (var doc in ppmDocs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final scheduledDate = data['scheduleddate'];
      DateTime? schedDateDt;
      if (scheduledDate is Timestamp) schedDateDt = scheduledDate.toDate();

      if (status == 'completed') {
        completed++;
      } else if (schedDateDt != null) {
        if (schedDateDt.isAfter(now) ||
            schedDateDt.isAtSameMomentAs(
              DateTime(now.year, now.month, now.day),
            )) {
          scheduled++;
        } else if (schedDateDt.isBefore(now) && status != 'completed') {
          delayed++;
        }
      }
    }

    // Breakdown
    final bdSnap =
        await FirebaseFirestore.instance.collection('BreakdownReports').get();
    int pending = 0, assigned = 0, resolved = 0;
    final bdDocs = bdSnap.docs;
    for (var doc in bdDocs) {
      final data = doc.data();
      final status = (data['Maintenancestatus'] ?? '').toString().toLowerCase();
      if (status == 'pending') {
        pending++;
      } else if (status == 'assigned') {
        assigned++;
      } else if (status == 'resolved' || status == 'completed') {
        resolved++;
      }
    }

    // Recent Activity
    final List<Map<String, dynamic>> ppmEvents =
        ppmDocs.map((doc) {
          final data = doc.data();
          final scheduledDate = data['scheduleddate'];
          DateTime? schedDt =
              scheduledDate is Timestamp ? scheduledDate.toDate() : null;
          return {
            "type": "PPM",
            "title":
                "PPM: ${data['assetname'] ?? ''} (${data['assetID'] ?? ''})",
            "desc": "Status: ${data['status'] ?? 'N/A'}",
            "time": schedDt ?? DateTime.now(),
          };
        }).toList();
    final List<Map<String, dynamic>> breakdownEvents =
        bdDocs.map((doc) {
          final data = doc.data();
          final reportedDt = data['ReportedDateTime'];
          DateTime? repDt =
              reportedDt is Timestamp ? reportedDt.toDate() : null;
          return {
            "type": "Breakdown",
            "title": "Breakdown: ${data['AssetID'] ?? ''}",
            "desc":
                "Status: ${data['Maintenancestatus'] ?? 'Pending'}"
                "${data['Reportedby'] != null ? ', Reported by ${data['Reportedby']}' : ''}",
            "time": repDt ?? DateTime.now(),
          };
        }).toList();
    final allActivities = [...ppmEvents, ...breakdownEvents];
    allActivities.sort((a, b) {
      final at = a['time'] as DateTime;
      final bt = b['time'] as DateTime;
      return bt.compareTo(at);
    });

    setState(() {
      ppmScheduledCount = scheduled;
      ppmCompletedCount = completed;
      ppmDelayedCount = delayed;
      bdPendingCount = pending;
      bdAssignedCount = assigned;
      bdResolvedCount = resolved;
      recentActivity = allActivities.take(10).toList();
      loading = false;
    });
  }

  String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays == 1) return "Yesterday";
    return DateFormat('dd MMM').format(dt);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        // Dashboard tab - you are already here, no navigation needed
        break;
      case 1:
        // Navigate to MaintenanceScheduleScreen for PPM
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MaintenanceScheduleScreen()),
        );
        break;
      case 2:
        // Navigate to BreakdownReportsScreen for Breakdown
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BreakdownReportsScreen()),
        );
        break;
    }
  }

  // Card Box UI
  Widget _buildSummaryBox(int count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(minHeight: 70),
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 23),
              SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(fontSize: 12.5, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Maintenance',
            style: TextStyle(
              color: Colors.white, // <-- Ensures the header text is WHITE
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ), // Also keep the back arrow white
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: appBlue, // #004EFF
        ),
        backgroundColor: Colors.grey[50],
        body:
            loading
                ? Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PPM Maintenance Summary
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          top: 4,
                          bottom: 2,
                        ),
                        child: Text(
                          'PPM Maintenance',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildSummaryBox(
                            ppmScheduledCount,
                            'Scheduled',
                            appBlue,
                            Icons.schedule,
                          ),
                          _buildSummaryBox(
                            ppmCompletedCount,
                            'Completed',
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _buildSummaryBox(
                            ppmDelayedCount,
                            'Delayed',
                            Colors.red,
                            Icons.error_outline,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          top: 14,
                          bottom: 2,
                        ),
                        child: Text(
                          'Breakdown Maintenance',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildSummaryBox(
                            bdPendingCount,
                            'Pending',
                            Colors.orange,
                            Icons.hourglass_empty,
                          ),
                          _buildSummaryBox(
                            bdAssignedCount,
                            'Assigned',
                            Colors.blueGrey,
                            Icons.assignment_ind,
                          ),
                          _buildSummaryBox(
                            bdResolvedCount,
                            'Resolved',
                            Colors.green,
                            Icons.check_circle_outline,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          top: 18,
                          bottom: 3,
                        ),
                        child: Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            recentActivity.isEmpty
                                ? Center(child: Text('No recent activity.'))
                                : ListView.builder(
                                  itemCount: recentActivity.length,
                                  itemBuilder: (context, index) {
                                    final item = recentActivity[index];
                                    final dt = item['time'] as DateTime;
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 2,
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          item['type'] == 'PPM'
                                              ? Icons.assignment
                                              : Icons.warning_amber_rounded,
                                          color:
                                              item['type'] == 'PPM'
                                                  ? appBlue
                                                  : Colors.orange,
                                        ),
                                        title: Text(
                                          item['title'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          item['desc'] ?? '',
                                          style: TextStyle(fontSize: 12.5),
                                        ),
                                        trailing: Text(
                                          timeAgo(dt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Color(0xFF004EFF), // Blue ONLY for the current tab
          unselectedItemColor: Colors.black, // Black for all other tabs
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'PPM',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'Breakdown',
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
