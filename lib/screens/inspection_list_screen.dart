import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_inspections.dart';
import 'qr_scanner_screen.dart';
import 'checkpoint_screen.dart';

class InspectionListScreen extends StatelessWidget {
  const InspectionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspections')),
      body: ListView.builder(
        itemCount: mockInspections.length,
        itemBuilder: (context, index) {
          final inspection = mockInspections[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.assignment),
              title: Text('${inspection.assetName} (${inspection.assetId})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Checklist: ${inspection.checklistId}'),
                  Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(inspection.checkingDate)}',
                  ),
                  Text('Status: ${inspection.status}'),
                  Text('Checked By: ${inspection.checkedBy}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final scannedAssetId = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                  );

                  if (scannedAssetId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CheckpointScreen(assetId: scannedAssetId),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
