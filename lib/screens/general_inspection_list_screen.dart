import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/assigned_inspection_checklist.dart'; // Adjust import path
import 'general_checkpoint_submission_screen.dart';
import 'generalsubmittedcheckpointsscreen.dart'; // Adjust import path
import '../inspections/module_selection_screen.dart';

class GeneralInspectionListScreen extends StatefulWidget {
  const GeneralInspectionListScreen({super.key});

  @override
  State<GeneralInspectionListScreen> createState() =>
      _GeneralInspectionListScreenState();
}

class _GeneralInspectionListScreenState
    extends State<GeneralInspectionListScreen> {
  List<AssignedInspectionChecklist> inspections = [];
  List<AssignedInspectionChecklist> filteredInspections = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    fetchInspections();
  }

  Future<void> fetchInspections() async {
    setState(() => isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('AssignedInspectionCheckpoints')
              .get();

      final data =
          snapshot.docs
              .map(
                (doc) => AssignedInspectionChecklist.fromFirestore(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList();

      setState(() {
        inspections = data;
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load inspections: $e')));
    }
  }

  void applyFilters() {
    setState(() {
      final searchLower = searchQuery.toLowerCase();
      filteredInspections =
          inspections.where((item) {
            final matchesSearch = item.inspectionID.toLowerCase().contains(
              searchLower,
            );
            final matchesStatus =
                selectedStatus == 'All' ||
                item.status.toLowerCase() == selectedStatus.toLowerCase();
            return matchesSearch && matchesStatus;
          }).toList();
    });
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'delayed':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Future<void> _handleRefresh() async {
    await fetchInspections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
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
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            title: const Text('General Inspections'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Modules',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModuleSelectionScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // Search input on top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by Inspection ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                searchQuery = value;
                applyFilters();
              },
            ),
          ),

          // Status dropdown below search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(),
              ),
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                DropdownMenuItem(value: 'Delayed', child: Text('Delayed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedStatus = value;
                  applyFilters();
                }
              },
            ),
          ),

          const Divider(height: 1),

          // Inspection List with pull-to-refresh
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredInspections.isEmpty
                    ? const Center(child: Text('No inspections found.'))
                    : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        itemCount: filteredInspections.length,
                        itemBuilder: (context, index) {
                          final item = filteredInspections[index];
                          final statusColor = getStatusColor(item.status);
                          final isCompleted =
                              item.status.toLowerCase() == 'completed';

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: const Color(
                              0xFFE3F0FF,
                            ), // Light blue background matching header
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Inspection ID and action button row
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment_turned_in,
                                        color: Colors.blueAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Inspection ID: ${item.inspectionID}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),

                                      // View or Submit button with blue font
                                      if (isCompleted)
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            color: Color(0xFF004EFF),
                                          ),
                                          label: const Text(
                                            'View Inspections',
                                            style: TextStyle(
                                              color: Color(0xFF004EFF),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        GeneralSubmittedCheckpointsScreen(
                                                          inspectionId:
                                                              item.inspectionID,
                                                          category:
                                                              item.category,
                                                        ),
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF004EFF,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        GeneralCheckpointSubmissionScreen(
                                                          inspectionID:
                                                              item.inspectionID,
                                                          category:
                                                              item.category,
                                                          locationID:
                                                              item.locationID,
                                                        ),
                                              ),
                                            ).then((value) {
                                              if (value == 'submitted') {
                                                fetchInspections(); // Refresh after submission
                                              }
                                            });
                                          },
                                          child: const Text(
                                            'Submit Inspection',
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Additional details
                                  Text(
                                    'Scheduled Date: ${DateFormat('dd-MM-yyyy').format(item.scheduledDate)}',
                                  ),
                                  Text(
                                    'Assigned To: ${item.assignedTo}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Status: ${item.status}',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Remarks: ${item.remarks ?? "-"}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
