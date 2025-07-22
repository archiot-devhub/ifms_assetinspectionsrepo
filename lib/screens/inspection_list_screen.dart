import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_inspections.dart';

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
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to detail screen (optional)
              },
            ),
          );
        },
      ),
    );
  }
}
