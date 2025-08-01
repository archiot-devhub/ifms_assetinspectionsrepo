import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'maintenance_schedule_screen.dart';

class PPMSubmittedCheckpointsScreen extends StatelessWidget {
  final String assetId;
  final String checklistId;
  final String scheduledId;

  const PPMSubmittedCheckpointsScreen({
    Key? key,
    required this.assetId,
    required this.checklistId,
    required this.scheduledId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submitted PPM Checkpoints")),
      body: SafeArea(
        child: Column(
          children: [
            // Info bar
            Container(
              width: double.infinity,
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Asset ID: $assetId",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Checklist ID: $checklistId",
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Schedule ID: $scheduledId",
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('PPMmaintenanceresponses')
                        .where('scheduledid', isEqualTo: scheduledId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No submitted checkpoints found."),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final checkpoint =
                          data['checkpoint'] ?? 'Unnamed Checkpoint';
                      final response = data['response'] ?? '-';
                      final remarks =
                          (data['remarks'] ?? data['remark'] ?? '').toString();
                      final submittedBy = data['submittedby'] ?? '-';
                      // Parse timestamp to readable format
                      String submittedOn = '-';
                      if (data['submittedon'] != null) {
                        final ts = data['submittedon'];
                        if (ts is Timestamp) {
                          submittedOn = DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(ts.toDate());
                        } else if (ts is String) {
                          // fallback if string
                          submittedOn = ts;
                        }
                      }
                      // Removed imageUrl and image widget

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checkpoint,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    "Result: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    response,
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                              if (remarks.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Remarks: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          remarks,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "By: $submittedBy",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.history,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    submittedOn,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              // Image widget removed
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
