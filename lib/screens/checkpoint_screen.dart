import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'success_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/checkpoint.dart'; // Your model with checkpointID, checkpoint, inputType, response, remarks, image

class CheckpointScreen extends StatefulWidget {
  final String assetId;
  final String assetName;
  final String inspectionId;

  const CheckpointScreen({
    super.key,
    required this.assetId,
    required this.assetName,
    required this.inspectionId,
  });

  @override
  State<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  final picker = ImagePicker();
  List<Checkpoint> checkpoints = [];

  @override
  void initState() {
    super.initState();
    fetchCheckpoints();
  }

  Future<void> fetchCheckpoints() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('Checkpoints')
            .where('assetName', isEqualTo: widget.assetName)
            .get();

    final data =
        snapshot.docs
            .map((doc) => Checkpoint.fromFirestore(doc.data()))
            .toList();

    setState(() {
      checkpoints = data;
    });
  }

  Future<void> _pickImage(int index) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        checkpoints[index].image = File(picked.path);
      });
    }
  }

  Future<void> _submitChecklist() async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    final user = FirebaseAuth.instance.currentUser;
    final submittedBy = user?.email ?? 'Unknown User';

    try {
      for (var cp in checkpoints) {
        String? imageUrl;

        // Upload image if selected
        if (cp.image != null) {
          final fileName = '${widget.inspectionId}_${cp.checkpointID}.jpg';
          final ref = storage.ref().child('checkpoint_images/$fileName');
          final uploadTask = await ref.putFile(cp.image!);
          imageUrl = await uploadTask.ref.getDownloadURL();
        }

        // Save checkpoint submission
        await firestore.collection('SubmittedCheckpoints').add({
          'inspectionID': widget.inspectionId,
          'assetID': widget.assetId,
          'assetName': widget.assetName,
          'checkpointID': cp.checkpointID,
          'checkpoint': cp.checkpoint,
          'response': cp.response ?? '',
          'remarks': cp.remarks ?? '',
          'imageUrl': imageUrl ?? '',
          'submittedDate': Timestamp.now(),
          'submittedBy': submittedBy,
        });
      }

      // Update assigned checklist status to Submitted
      final assignedSnap =
          await firestore
              .collection('AssignedChecklists')
              .where('inspectionId', isEqualTo: widget.inspectionId)
              .limit(1)
              .get();

      if (assignedSnap.docs.isNotEmpty) {
        await assignedSnap.docs.first.reference.update({'status': 'Submitted'});
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkpoints - ${widget.assetName}')),
      body:
          checkpoints.isEmpty
              ? Center(
                child: Text(
                  'No checkpoints available for this asset.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: ListView(
                  children: [
                    // Asset Info Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Asset ID:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.assetId,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Asset Name:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.assetName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Checkpoints List
                    ...checkpoints.asMap().entries.map((entry) {
                      int index = entry.key;
                      Checkpoint cp = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cp.checkpoint,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // Yes Radio
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'Yes',
                                        groupValue: cp.response,
                                        onChanged: (value) {
                                          setState(() => cp.response = value);
                                        },
                                      ),
                                      const Text('Yes'),
                                    ],
                                  ),
                                ),
                                // No Radio
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'No',
                                        groupValue: cp.response,
                                        onChanged: (value) {
                                          setState(() => cp.response = value);
                                        },
                                      ),
                                      const Text('No'),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Remarks Input
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Enter remarks if any',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              onChanged: (text) => cp.remarks = text,
                            ),
                            const SizedBox(height: 10),

                            // Image Picker Section
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _pickImage(index),
                                  child: const Text("Add Picture"),
                                ),
                                const SizedBox(width: 12),
                                if (cp.image != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      cp.image!,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    // Submit Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitChecklist,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(160, 45),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
