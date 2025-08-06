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
  String? selectedStatus = 'All';

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
      fetchInspections(); // Refresh on re-entering screen
    }
    _isFirstLoad = false;
  }

  Future<void> fetchInspections() async {
    setState(() {
      isLoading = true;
    });
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
      debugPrint('Error fetching inspections: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInspections =
        inspections.where((inspection) {
          final searchLower = searchQuery.toLowerCase();
          final matchesSearch =
              inspection.assetName.toLowerCase().contains(searchLower) ||
              inspection.assetId.toLowerCase().contains(searchLower);

          final matchesStatus =
              selectedStatus == null ||
              selectedStatus == 'All' ||
              inspection.status == selectedStatus;

          return matchesSearch && matchesStatus;
        }).toList();

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
            iconTheme: const IconThemeData(
              color: Colors.white,
            ), // back icon white
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            title: const Text('Asset Inspections'),
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
          // Search and Status Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 400;

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by Asset ID or Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 8),
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
                          setState(() => selectedStatus = value);
                        },
                      ),
                    ],
                  );
                } else {
                  // Desktop / Wider screens
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search by Asset ID or Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() => searchQuery = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            setState(() => selectedStatus = value);
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          const Divider(height: 1),
          // List or Loading
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredInspections.isEmpty
                    ? const Center(child: Text('No inspections available'))
                    : RefreshIndicator(
                      onRefresh: () async {
                        await fetchInspections();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        itemCount: filteredInspections.length,
                        itemBuilder: (context, index) {
                          final inspection = filteredInspections[index];
                          final isSubmitted =
                              inspection.status.toLowerCase() == 'submitted';
                          final statusColor =
                              isSubmitted ? Colors.green : Colors.red;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Asset Name + ID + Icon
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment_outlined,
                                        color: Colors.blueAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${inspection.assetName} (${inspection.assetId})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isSubmitted
                                              ? Icons.visibility
                                              : Icons.qr_code_scanner,
                                          color:
                                              isSubmitted
                                                  ? Colors.blue
                                                  : Colors.black,
                                        ),
                                        tooltip:
                                            isSubmitted
                                                ? 'View Details'
                                                : 'Scan QR',
                                        onPressed: () async {
                                          if (isSubmitted) {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        SubmittedCheckpointsScreen(
                                                          inspectionId:
                                                              inspection
                                                                  .inspectionId,
                                                        ),
                                              ),
                                            );
                                          } else {
                                            final scannedAssetId =
                                                await Navigator.push<String>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            const QRScannerScreen(),
                                                  ),
                                                );
                                            if (scannedAssetId != null &&
                                                scannedAssetId
                                                    .trim()
                                                    .isNotEmpty) {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => CheckpointScreen(
                                                        assetId: scannedAssetId,
                                                        assetName:
                                                            inspection
                                                                .assetName,
                                                        inspectionId:
                                                            inspection
                                                                .inspectionId,
                                                      ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Date: ${DateFormat('dd-MM-yyyy').format(inspection.scheduledDate)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Status: ${inspection.status}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: statusColor,
                                    ),
                                  ),
                                  Text(
                                    'Checked By: ${inspection.checkedBy}',
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
