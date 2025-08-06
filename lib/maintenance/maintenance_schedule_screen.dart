import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/scheduled_ppm.dart';
import '../../maintenance/ppm_checkpoint_submission_screen.dart';
import '../../maintenance/maintenance_calendar_screen.dart';
import 'maintenance_submitted_checkpoints.dart';

class MaintenanceScheduleScreen extends StatefulWidget {
  const MaintenanceScheduleScreen({super.key});

  @override
  State<MaintenanceScheduleScreen> createState() =>
      _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen>
    with SingleTickerProviderStateMixin {
  List<ScheduledPPM> schedules = [];
  bool isLoading = true;
  String searchQuery = '';
  late TabController tabController;

  int upcomingCount = 0;
  int overdueCount = 0;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('MaintenanceSchedules')
              .orderBy('scheduleddate')
              .get();

      setState(() {
        schedules =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return ScheduledPPM.fromMap(data, doc.id);
            }).toList();
        isLoading = false;
      });
      updateCounts();
    } catch (e) {
      print('Error loading PPMs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateCounts() {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    int upcoming = 0;
    int overdue = 0;
    int completed = 0;

    final queryLower = searchQuery.toLowerCase();

    for (var ppm in schedules) {
      final assetNameLower = ppm.assetName.toLowerCase();
      final assetIdLower = ppm.assetId.toLowerCase();

      if (!(assetNameLower.contains(queryLower) ||
          assetIdLower.contains(queryLower))) {
        continue;
      }

      final scheduledDateOnly = DateTime(
        ppm.scheduledDate.year,
        ppm.scheduledDate.month,
        ppm.scheduledDate.day,
      );
      final statusLower = ppm.status.toLowerCase();

      if ((scheduledDateOnly.isAtSameMomentAs(todayDateOnly) ||
              scheduledDateOnly.isAfter(todayDateOnly)) &&
          statusLower != 'completed' &&
          statusLower != 'skipped') {
        upcoming++;
      } else if (scheduledDateOnly.isBefore(todayDateOnly) &&
          statusLower != 'completed' &&
          statusLower != 'skipped') {
        overdue++;
      } else if (statusLower == 'completed') {
        completed++;
      }
    }

    setState(() {
      upcomingCount = upcoming;
      overdueCount = overdue;
      completedCount = completed;
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  List<ScheduledPPM> filterByTab(String tab) {
    final today = DateTime.now();
    final queryLower = searchQuery.toLowerCase();

    return schedules.where((ppm) {
      final matchesSearch =
          ppm.assetName.toLowerCase().contains(queryLower) ||
          ppm.assetId.toLowerCase().contains(queryLower);

      final scheduledDate = ppm.scheduledDate;
      final statusLower = ppm.status.toLowerCase();

      if (!matchesSearch) return false;

      DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
      DateTime scheduledDateOnly = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      );

      switch (tab) {
        case 'Upcoming':
          return (scheduledDateOnly.isAtSameMomentAs(todayDateOnly) ||
                  scheduledDateOnly.isAfter(todayDateOnly)) &&
              statusLower != 'completed' &&
              statusLower != 'skipped';

        case 'Overdue':
          return scheduledDateOnly.isBefore(todayDateOnly) &&
              statusLower != 'completed' &&
              statusLower != 'skipped';
        case 'Completed':
          return statusLower == 'completed';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
          kToolbarHeight + 48,
        ), // 48 for the TabBar
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004EFF), Color(0xFF002F99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white), // icons white
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            title: const Text('Scheduled PPMs'),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                ), // icon white
                tooltip: 'Calendar view',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaintenanceCalendarScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ), // icon white
                tooltip: 'Refresh',
                onPressed: () {
                  setState(() => isLoading = true);
                  fetchSchedules();
                },
              ),
            ],
            bottom: TabBar(
              controller: tabController,
              labelColor: Colors.white, // active tab label color white
              unselectedLabelColor:
                  Colors.white60, // unselected tab label color light white
              indicatorColor: Colors.white, // indicator white
              tabs: [
                Tab(text: "Upcoming ($upcomingCount)"),
                Tab(text: "Overdue ($overdueCount)"),
                Tab(text: "Completed ($completedCount)"),
              ],
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: 10,
            right: 10,
            bottom: 0,
          ),
          child: Column(
            children: [
              // Search input & Status dropdown
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search by Asset ID or Name',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        updateCounts();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // TABS: Upcoming | Overdue | Completed
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                          controller: tabController,
                          children: [
                            _PPMListWidget(
                              tab: 'Upcoming',
                              data: filterByTab('Upcoming'),
                              fetchSchedules: fetchSchedules,
                            ),
                            _PPMListWidget(
                              tab: 'Overdue',
                              data: filterByTab('Overdue'),
                              fetchSchedules: fetchSchedules,
                            ),
                            _PPMListWidget(
                              tab: 'Completed',
                              data: filterByTab('Completed'),
                              fetchSchedules: fetchSchedules,
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PPMListWidget extends StatelessWidget {
  final List<ScheduledPPM> data;
  final Future<void> Function() fetchSchedules;
  final String tab;

  const _PPMListWidget({
    required this.data,
    required this.fetchSchedules,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No Scheduled PPMs found'));
    }
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final ppm = data[index];
        final statusColor =
            ppm.status == 'Completed'
                ? Colors.green
                : ppm.status == 'Skipped'
                ? Colors.orange
                : Colors.blue;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & ID
                Row(
                  children: [
                    const Icon(Icons.build_circle, color: Colors.blueAccent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${ppm.assetName} (${ppm.assetId})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Project: ${ppm.project}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Plan: ${ppm.planName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 17,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${DateFormat('dd-MM-yyyy').format(ppm.scheduledDate)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        ppm.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(
                      tab == 'Completed'
                          ? Icons.visibility_outlined
                          : Icons.edit_outlined,
                      size: 19,
                    ),
                    label: Text(
                      tab == 'Completed' ? 'View Details' : 'Submit Checklist',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                    onPressed: () async {
                      if (tab == 'Completed') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PPMSubmittedCheckpointsScreen(
                                  assetId: ppm.assetId,
                                  checklistId:
                                      ppm.planName, // Adjust if you have actual checklistId
                                  scheduledId: ppm.scheduleId,
                                ),
                          ),
                        );
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PPMCheckpointSubmissionScreen(
                                  docId: ppm.docId,
                                  scheduleId: ppm.scheduleId,
                                  checklistName: ppm.planName,
                                ),
                          ),
                        );
                        if (result == 'submitted') {
                          fetchSchedules();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
