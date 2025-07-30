import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/scheduled_ppm.dart';
import '../../maintenance/ppm_checkpoint_submission_screen.dart';
import '../../maintenance/maintenance_calendar_screen.dart';

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
    } catch (e) {
      print('Error loading PPMs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  List<ScheduledPPM> filterByTab(String tab) {
    final today = DateTime.now();

    return schedules.where((ppm) {
      // Standard search and status dropdown filtering
      final matchesSearch =
          ppm.assetName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          ppm.assetId.toLowerCase().contains(searchQuery.toLowerCase());

      final scheduledDate = ppm.scheduledDate;
      final status = ppm.status;

      if (!matchesSearch) return false;

      switch (tab) {
        case 'Upcoming':
          return scheduledDate.isAfter(today) &&
              status != 'Completed' &&
              status != 'Skipped';
        case 'Overdue':
          return scheduledDate.isBefore(
                DateTime(today.year, today.month, today.day),
              ) &&
              status != 'Completed' &&
              status != 'Skipped';
        case 'Completed':
          return status == 'Completed';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled PPMs'),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => isLoading = true);
              fetchSchedules();
            },
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Overdue"),
            Tab(text: "Completed"),
          ],
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
                      onChanged: (value) => setState(() => searchQuery = value),
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
                            // Upcoming
                            _PPMListWidget(
                              data: filterByTab('Upcoming'),
                              fetchSchedules: fetchSchedules,
                            ),
                            // Overdue
                            _PPMListWidget(
                              data: filterByTab('Overdue'),
                              fetchSchedules: fetchSchedules,
                            ),
                            // Completed
                            _PPMListWidget(
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
  const _PPMListWidget({required this.data, required this.fetchSchedules});

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
                    icon: const Icon(Icons.visibility_outlined, size: 19),
                    label: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 13.5),
                    ),
                    onPressed: () async {
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
