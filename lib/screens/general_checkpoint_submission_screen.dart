import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/checkpoint.dart';
import 'general_success_screen.dart';

class GeneralCheckpointSubmissionScreen extends StatefulWidget {
  final String inspectionID;
  final String category;
  final String locationID;

  const GeneralCheckpointSubmissionScreen({
    super.key,
    required this.inspectionID,
    required this.category,
    required this.locationID,
  });

  @override
  State<GeneralCheckpointSubmissionScreen> createState() =>
      _GeneralCheckpointSubmissionScreenState();
}

class _GeneralCheckpointSubmissionScreenState
    extends State<GeneralCheckpointSubmissionScreen> {
  List<Checkpoint> checkpoints = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchCheckpoints();
  }

  Future<void> fetchCheckpoints() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('GeneralInspectionCheckpoints')
              .where('category', isEqualTo: widget.category)
              .get();

      setState(() {
        checkpoints =
            snapshot.docs
                .map((doc) => Checkpoint.fromFirestore(doc.data()))
                .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading checkpoints: $e')));
    }
  }

  Future<void> pickImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        checkpoints[index].image = File(picked.path);
      });
    }
  }

  Future<void> submitCheckpoints() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      for (var cp in checkpoints) {
        String? imageUrl;

        if (cp.image != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('general_inspection_images')
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

          await ref.putFile(cp.image!);
          imageUrl = await ref.getDownloadURL();
        }

        await FirebaseFirestore.instance
            .collection('SubmittedInspectionCheckpoints')
            .add({
              'inspectionID': widget.inspectionID,
              'locationID': widget.locationID,
              'checkpointID': cp.checkpointID,
              'checkpoint': cp.checkpoint,
              'response': cp.response,
              'remarks': cp.remarks,
              'imageUrl': imageUrl,
              'submittedOn': Timestamp.now(),
            });
      }

      // NEW (safe update)
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('AssignedInspectionCheckpoints')
              .where('inspectionID', isEqualTo: widget.inspectionID)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('AssignedInspectionCheckpoints')
            .doc(docId)
            .update({'status': 'Submitted'});
      } else {
        throw Exception(
          "AssignedInspectionCheckpoints document not found for inspectionID: ${widget.inspectionID}",
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GeneralSuccessScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    }
  }

  Widget buildInputField(Checkpoint cp, int index) {
    switch (cp.inputType) {
      case 'radio':
        return Column(
          children:
              ['Yes', 'No'].map((option) {
                return RadioListTile<String>(
                  value: option,
                  groupValue: cp.response,
                  onChanged: (val) {
                    setState(() {
                      cp.response = val!;
                    });
                  },
                  title: Text(option),
                );
              }).toList(),
        );
      case 'text':
        return TextFormField(
          initialValue: cp.response,
          decoration: const InputDecoration(
            hintText: 'Enter response',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Response required';
            }
            return null;
          },
          onChanged: (val) => cp.response = val.trim(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit General Inspection')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView.builder(
                  itemCount: checkpoints.length,
                  itemBuilder: (context, index) {
                    final cp = checkpoints[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cp.checkpoint,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildInputField(cp, index),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Remarks (optional)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) => cp.remarks = val,
                            ),
                            const SizedBox(height: 8),
                            if (cp.image != null)
                              Image.file(
                                cp.image!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            TextButton.icon(
                              onPressed: () => pickImage(index),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Upload Image'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitCheckpoints,
        label: const Text('Submit'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
