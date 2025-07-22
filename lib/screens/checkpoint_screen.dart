import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Checkpoint {
  final String question;
  String? response; // Yes/No
  String? remarks;
  File? image;

  Checkpoint({required this.question});
}

class CheckpointScreen extends StatefulWidget {
  final String assetId;
  final String assetName; // ✅ Add this

  const CheckpointScreen({
    super.key,
    required this.assetId,
    required this.assetName, // ✅ Accept assetName
  });

  @override
  State<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  final picker = ImagePicker();

  List<Checkpoint> checkpoints = [
    Checkpoint(question: 'Is the compressor running without alarm?'),
    Checkpoint(question: 'Is chilled water inlet/outlet temperature normal?'),
    Checkpoint(question: 'Is condenser pressure within safe range?'),
    Checkpoint(question: 'Are the evaporator and condenser tubes clean?'),
    Checkpoint(question: 'Is the control panel showing no faults?'),
  ];

  Future<void> _pickImage(int index) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        checkpoints[index].image = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Checklist')),
      body: Padding(
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
                  Text(cp.question, style: const TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Yes',
                        groupValue: cp.response,
                        onChanged:
                            (value) => setState(() => cp.response = value),
                      ),
                      const Text('Yes'),
                      Radio<String>(
                        value: 'No',
                        groupValue: cp.response,
                        onChanged:
                            (value) => setState(() => cp.response = value),
                      ),
                      const Text('No'),
                    ],
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter Remarks here, if any',
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
            }).toList(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // You can save or submit data here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checklist submitted!')),
                  );
                },
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
