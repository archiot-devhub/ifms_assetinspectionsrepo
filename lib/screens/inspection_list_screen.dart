import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/AssignedChecklist.dart';
import 'qr_scanner_screen.dart';
import 'checkpoint_screen.dart';
import 'SubmittedCheckpointsScreen.dart';
import '../inspections/module_selection_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  String searchQuery = '';
  String? selectedStatus;

  final String username = 'adspl1005';
  final String role = 'Technician';

  List<AssignedChecklist> inspections = [];
  bool isLoading = true;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    fetchInspections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isFirstLoad) {
      fetchInspections(); // Refresh when coming back to screen
    }
    _isFirstLoad = false;
  }

  Future<void> fetchInspections() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('AssignedChecklists')
              .get();

      setState(() {
        inspections =
            querySnapshot.docs
                .map((doc) => AssignedChecklist.fromMap(doc.data()))
                .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching inspections: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInspections =
        inspections.where((inspection) {
          final matchesSearch =
              inspection.assetName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              inspection.assetId.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );

          final matchesStatus =
              selectedStatus == null ||
              selectedStatus == 'All' ||
              inspection.status == selectedStatus;

          return matchesSearch && matchesStatus;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspections'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Modules',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ModuleSelectionScreen()),
            );
          },
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  // Mobile View
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search by Asset ID or Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Reload Inspections',
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                              });
                              fetchInspections();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Status',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(
                            value: 'Submitted',
                            child: Text('Submitted'),
                          ),
                          DropdownMenuItem(
                            value: 'Not Submitted',
                            child: Text('Not Submitted'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ],
                  );
                } else {
                  // Desktop View
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search by Asset ID or Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Reload Inspections',
                              onPressed: () {
                                setState(() {
                                  isLoading = true;
                                });
                                fetchInspections();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Status',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(
                              value: 'Submitted',
                              child: Text('Submitted'),
                            ),
                            DropdownMenuItem(
                              value: 'Not Submitted',
                              child: Text('Not Submitted'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: filteredInspections.length,
                      itemBuilder: (context, index) {
                        final inspection = filteredInspections[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: const Icon(Icons.assignment),
                            title: Text(
                              '${inspection.assetName} (${inspection.assetId})',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${DateFormat('dd-MM-yyyy').format(inspection.scheduledDate)}',
                                ),
                                Text(
                                  'Status: ${inspection.status}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        inspection.status == 'Submitted'
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                Text('Checked By: ${inspection.checkedBy}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                inspection.status == 'Submitted'
                                    ? Icons.visibility
                                    : Icons.qr_code_scanner,
                                color:
                                    inspection.status == 'Submitted'
                                        ? Colors.blue
                                        : null,
                              ),
                              tooltip:
                                  inspection.status == 'Submitted'
                                      ? 'View Details'
                                      : 'Scan QR',
                              onPressed: () async {
                                if (inspection.status == 'Submitted') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => SubmittedCheckpointsScreen(
                                            inspectionId:
                                                inspection.inspectionId,
                                          ),
                                    ),
                                  );
                                } else {
                                  final scannedAssetId = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const QRScannerScreen(),
                                    ),
                                  );

                                  if (scannedAssetId != null &&
                                      scannedAssetId
                                          .toString()
                                          .trim()
                                          .isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => CheckpointScreen(
                                              assetId: scannedAssetId,
                                              assetName: inspection.assetName,
                                              inspectionId:
                                                  inspection.inspectionId,
                                            ),
                                      ),
                                    );
                                  }
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
