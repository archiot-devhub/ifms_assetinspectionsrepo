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
          'submittedby': 'Technician',
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
    final theme = Theme.of(context);

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
              fontWeight: FontWeight.w600,
            ),
            title: Text(
              widget.checklistName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  (checkpoints.isEmpty)
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 18,
                        ),
                        itemCount: checkpoints.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cp = checkpoints[index];
                          final docId = cp['docId'];
                          final checkpointName =
                              cp['checkpointname'] ?? cp['checkpoint'] ?? 'N/A';

                          return Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkpoint name (always visible, multiline if needed)
                                  Text(
                                    checkpointName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.5,
                                          color: Colors.black,
                                        ),
                                  ),
                                  const SizedBox(height: 7),
                                  // Select Yes/No/N/A
                                  Row(
                                    children:
                                        ['Yes', 'No', 'N/A'].map((option) {
                                          return Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Radio<String>(
                                                  value: option,
                                                  groupValue:
                                                      responses[docId] ?? '',
                                                  onChanged: (value) {
                                                    setState(() {
                                                      responses[docId] = value;
                                                    });
                                                  },
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                Text(
                                                  option,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                  const SizedBox(height: 5),
                                  // Remarks textbox
                                  TextFormField(
                                    minLines: 1,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Remarks',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                    ),
                                    initialValue:
                                        responses['remark_$docId'] ?? '',
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
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 18,
                top: 8,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: isSubmitting ? null : submitResponses,
                  icon: const Icon(Icons.check_circle),
                  label:
                      isSubmitting
                          ? const Text('Submitting...')
                          : const Text('Submit Checklist'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
