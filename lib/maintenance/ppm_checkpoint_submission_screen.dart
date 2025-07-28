import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PPMCheckpointSubmissionScreen extends StatefulWidget {
  final String docId; // Firestore document ID of the MaintenanceSchedule
  final String scheduleId; // Custom schedule ID (used in responses)
  final String checklistName;

  const PPMCheckpointSubmissionScreen({
    super.key,
    required this.docId,
    required this.scheduleId,
    required this.checklistName,
  });

  @override
  State<PPMCheckpointSubmissionScreen> createState() =>
      _PPMCheckpointSubmissionScreenState();
}

class _PPMCheckpointSubmissionScreenState
    extends State<PPMCheckpointSubmissionScreen> {
  List<Map<String, dynamic>> checkpoints = [];
  Map<String, dynamic> responses = {};
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchCheckpoints();
  }

  Future<void> fetchCheckpoints() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('PPMcheckpoints')
              .where('checklistname', isEqualTo: widget.checklistName)
              .get();

      if (snapshot.docs.isEmpty) {
        Fluttertoast.showToast(
          msg: '⚠️ No checkpoints found for this checklist.',
        );
        return;
      }

      setState(() {
        checkpoints =
            snapshot.docs.map((doc) {
              final data = doc.data();
              data['docId'] = doc.id; // Use Firestore doc ID as unique key
              return data;
            }).toList();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Failed to load checkpoints: $e');
    }
  }

  Future<void> submitResponses() async {
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final scheduleDocRef = FirebaseFirestore.instance
          .collection('MaintenanceSchedules')
          .doc(widget.docId);

      final docSnapshot = await scheduleDocRef.get();
      if (!docSnapshot.exists) {
        Fluttertoast.showToast(msg: '⚠️ Schedule not found: ${widget.docId}');
        setState(() => isSubmitting = false);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final responseCollection = FirebaseFirestore.instance.collection(
        'PPMmaintenanceresponses',
      );

      for (var cp in checkpoints) {
        final checkpointDocId = cp['docId'];
        final checklistId = cp['checklistID'] ?? '';
        final checkpoint = cp['checkpoint'] ?? '';
        final checkpointName = cp['checkpointname'] ?? checkpoint;
        final response = responses[checkpointDocId] ?? '';
        final remark = responses['remark_$checkpointDocId'] ?? '';

        if (checklistId.isEmpty ||
            checkpoint.isEmpty ||
            checkpointDocId == null) {
          continue;
        }

        batch.set(responseCollection.doc(), {
          'checklistid': checklistId,
          'checkpoint': checkpoint,
          'checkpointname': checkpointName,
          'response': response,
          'remarks': remark,
          'scheduledid': widget.scheduleId,
          'submittedby': 'Technician', // Replace with user info if needed
          'submittedon': Timestamp.now(),
        });
      }

      batch.update(scheduleDocRef, {
        'status': 'Completed',
        'completedon': Timestamp.now(),
      });

      await batch.commit();

      Fluttertoast.showToast(msg: '✅ Checklist submitted successfully!');
      Navigator.pop(context, 'submitted');
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Submission failed: $e');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PPM: ${widget.checklistName}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  checkpoints.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: checkpoints.length,
                        itemBuilder: (context, index) {
                          final cp = checkpoints[index];
                          final docId = cp['docId'];
                          final checkpointName =
                              cp['checkpointname'] ?? cp['checkpoint'] ?? 'N/A';

                          return Card(
                            margin: const EdgeInsets.all(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    checkpointName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children:
                                        ['Yes', 'No', 'N/A'].map((option) {
                                          return Expanded(
                                            child: Row(
                                              children: [
                                                Radio<String>(
                                                  value: option,
                                                  groupValue: responses[docId],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      responses[docId] = value;
                                                    });
                                                  },
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                Text(option),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Remarks',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      responses['remark_$docId'] = value;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : submitResponses,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Submit Checklist'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
