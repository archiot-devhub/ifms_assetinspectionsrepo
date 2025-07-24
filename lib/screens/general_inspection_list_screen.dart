import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assigned_inspection_checklist.dart';
import 'general_checkpoint_submission_screen.dart';

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
      filteredInspections =
          inspections.where((item) {
            final matchesSearch = item.inspectionID.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            final matchesStatus =
                selectedStatus == 'All'
                    ? true
                    : item.status.toLowerCase() == selectedStatus.toLowerCase();
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

  IconData getTrailingIcon(String status) {
    return status.toLowerCase() == 'completed'
        ? Icons.remove_red_eye
        : Icons.assignment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('General Inspections')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 🔍 Search Bar & Reload
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search by Inspection ID',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              searchQuery = value;
                              applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: fetchInspections,
                          tooltip: 'Reload Inspections',
                        ),
                      ],
                    ),
                  ),

                  // 🔽 Status Dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Text('Filter by Status:'),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
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
                              value: 'Delayed',
                              child: Text('Delayed'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              selectedStatus = value;
                              applyFilters();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 📋 List
                  Expanded(
                    child:
                        filteredInspections.isEmpty
                            ? const Center(child: Text('No inspections found.'))
                            : ListView.builder(
                              itemCount: filteredInspections.length,
                              itemBuilder: (context, index) {
                                final item = filteredInspections[index];
                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      'Inspection ID: ${item.inspectionID}',
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Scheduled Date: ${item.scheduledDate.toLocal().toString().split(' ')[0]}',
                                        ),
                                        Text('Assigned To: ${item.assignedTo}'),
                                        Text(
                                          'Status: ${item.status}',
                                          style: TextStyle(
                                            color: getStatusColor(item.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        Text('Remarks: ${item.remarks ?? "-"}'),
                                        Text(
                                          'Completed On: ${item.completedOn != null ? item.completedOn!.toLocal().toString().split(' ')[0] : "-"}',
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        getTrailingIcon(item.status),
                                        color:
                                            item.status.toLowerCase() ==
                                                    'completed'
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                      tooltip:
                                          item.status.toLowerCase() ==
                                                  'completed'
                                              ? 'View Submitted Checklist'
                                              : 'Submit Checklist',
                                      onPressed: () {
                                        if (item.status.toLowerCase() ==
                                            'completed') {
                                          // TODO: Navigate to view submitted checklist
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      GeneralCheckpointSubmissionScreen(
                                                        inspectionID:
                                                            item.inspectionID,
                                                        category: item.category,
                                                        locationID:
                                                            item.locationID,
                                                      ),
                                            ),
                                          ).then((value) {
                                            if (value == 'submitted') {
                                              fetchInspections(); // refresh after submission
                                            }
                                          });
                                        }
                                      },
                                    ),
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
