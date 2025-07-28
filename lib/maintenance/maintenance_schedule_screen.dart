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

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen> {
  List<ScheduledPPM> schedules = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('MaintenanceSchedules')
              .get();

      setState(() {
        schedules =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return ScheduledPPM.fromMap(
                data,
                doc.id,
              ); // doc.id = Firestore document ID
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
  Widget build(BuildContext context) {
    final filteredSchedules =
        schedules.where((ppm) {
          final matchesSearch =
              ppm.assetName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              ppm.assetId.toLowerCase().contains(searchQuery.toLowerCase());
          final matchesStatus =
              selectedStatus == null ||
              selectedStatus == 'All' ||
              ppm.status == selectedStatus;
          return matchesSearch && matchesStatus;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled PPMs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
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
            onPressed: () {
              setState(() => isLoading = true);
              fetchSchedules();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by Asset ID or Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(
                        value: 'Scheduled',
                        child: Text('Scheduled'),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'Skipped',
                        child: Text('Skipped'),
                      ),
                    ],
                    onChanged:
                        (value) => setState(() => selectedStatus = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: filteredSchedules.length,
                      itemBuilder: (context, index) {
                        final ppm = filteredSchedules[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.build),
                            title: Text('${ppm.assetName} (${ppm.assetId})'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Project: ${ppm.project}'),
                                Text('Plan: ${ppm.planName}'),
                                Text(
                                  'Scheduled: ${DateFormat('dd-MM-yyyy').format(ppm.scheduledDate)}',
                                ),
                                Text(
                                  'Status: ${ppm.status}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        ppm.status == 'Completed'
                                            ? Colors.green
                                            : ppm.status == 'Skipped'
                                            ? Colors.orange
                                            : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (
                                        context,
                                      ) => PPMCheckpointSubmissionScreen(
                                        docId:
                                            ppm.docId, // ← use docId for update
                                        scheduleId:
                                            ppm.scheduleId, // ← optional: still pass if needed
                                        checklistName: ppm.planName,
                                      ),
                                ),
                              );
                              if (result == 'submitted') {
                                fetchSchedules();
                              }
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
