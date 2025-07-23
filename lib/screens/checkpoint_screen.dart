import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/checkpoint.dart'; // ✅ Your model should have: checkpointID, checkpoint, inputType, response, remarks, image

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

    try {
      for (var cp in checkpoints) {
        String? imageUrl;

        // ✅ Upload image if exists
        if (cp.image != null) {
          final fileName = '${widget.inspectionId}_${cp.checkpointID}.jpg';
          final ref = storage.ref().child('checkpoint_images/$fileName');
          final uploadTask = await ref.putFile(cp.image!);
          imageUrl = await uploadTask.ref.getDownloadURL();
        }

        // ✅ Save to SubmittedCheckpoints
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
        });
      }

      // ✅ Update AssignedChecklists status to 'Submitted'
      final assignedSnap =
          await firestore
              .collection('AssignedChecklists')
              .where('inspectionId', isEqualTo: widget.inspectionId)
              .limit(1)
              .get();

      if (assignedSnap.docs.isNotEmpty) {
        await assignedSnap.docs.first.reference.update({'status': 'Submitted'});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist submitted successfully!')),
      );

      Navigator.pop(context); // Optional: go back
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
                padding: const EdgeInsets.all(12.0),
                child: ListView(
                  children: [
                    Text(
                      "Asset ID: ${widget.assetId}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Asset Name: ${widget.assetName}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...checkpoints.asMap().entries.map((entry) {
                      int index = entry.key;
                      var cp = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cp.checkpoint,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'Yes',
                                groupValue: cp.response,
                                onChanged:
                                    (value) =>
                                        setState(() => cp.response = value),
                              ),
                              const Text('Yes'),
                              Radio<String>(
                                value: 'No',
                                groupValue: cp.response,
                                onChanged:
                                    (value) =>
                                        setState(() => cp.response = value),
                              ),
                              const Text('No'),
                            ],
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Enter remarks if any',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (text) => cp.remarks = text,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _pickImage(index),
                                child: const Text("Add Picture"),
                              ),
                              const SizedBox(width: 10),
                              if (cp.image != null)
                                Image.file(
                                  cp.image!,
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                ),
                            ],
                          ),
                          const Divider(height: 20),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitChecklist,
                        child: const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
