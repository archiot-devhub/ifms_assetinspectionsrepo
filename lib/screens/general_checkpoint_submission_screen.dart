import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    if (!_formKey.currentState!.validate()) {
      // Optionally Scroll to top or show a toast here
      return;
    }

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
              'imageUrl': imageUrl ?? '',
              'submittedOn': Timestamp.now(),
            });
      }

      // Update Inspection status to Submitted
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
          mainAxisSize: MainAxisSize.min,
          children:
              ['Yes', 'No'].map((option) {
                return RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  value: option,
                  groupValue: cp.response,
                  onChanged: (val) {
                    setState(() {
                      cp.response = val!;
                    });
                  },
                );
              }).toList(),
        );
      case 'text':
        return TextFormField(
          initialValue: cp.response ?? '',
          decoration: const InputDecoration(
            hintText: 'Enter response',
            isDense: true,
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
            ), // back icon color
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            title: Text('Checklist: ${widget.category}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemCount: checkpoints.length,
                            itemBuilder: (context, index) {
                              final cp = checkpoints[index];

                              return Card(
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cp.checkpoint,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      buildInputField(cp, index),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        minLines: 1,
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                          labelText: 'Remarks (optional)',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        initialValue: cp.remarks ?? '',
                                        onChanged: (val) => cp.remarks = val,
                                      ),
                                      const SizedBox(height: 8),
                                      if (cp.image != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            cp.image!,
                                            height: 80,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      TextButton.icon(
                                        onPressed: () => pickImage(index),
                                        icon: const Icon(Icons.camera_alt),
                                        label: const Text('Upload Image'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 0,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF004EFF,
                                  ), // Header blue
                                  foregroundColor: Colors.white, // White text
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: submitCheckpoints,
                                child: const Text('Submit Checklist'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
