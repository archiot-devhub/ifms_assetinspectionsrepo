import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_inspections.dart';
import 'qr_scanner_screen.dart';
import 'checkpoint_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  String searchQuery = '';
  String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final filteredInspections =
        mockInspections.where((inspection) {
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
      appBar: AppBar(title: const Text('Inspections')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
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
                const SizedBox(width: 10),
                Expanded(
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
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                        Text('Checklist: ${inspection.checklistId}'),
                        Text(
                          'Date: ${DateFormat('dd-MM-yyyy').format(inspection.checkingDate)}',
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
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final scannedAssetId = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QRScannerScreen(),
                          ),
                        );

                        if (scannedAssetId != null &&
                            scannedAssetId.toString().trim().isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CheckpointScreen(
                                    assetId: scannedAssetId,
                                    assetName: inspection.assetName,
                                  ),
                            ),
                          );
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
