import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class BulkUploadAssetScreen extends StatefulWidget {
  const BulkUploadAssetScreen({super.key});

  @override
  State<BulkUploadAssetScreen> createState() => _BulkUploadAssetScreenState();
}

class _BulkUploadAssetScreenState extends State<BulkUploadAssetScreen> {
  List<List<dynamic>> _csvData = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final csvTable = const CsvToListConverter().convert(content, eol: '\n');

      setState(() {
        _csvData = csvTable;
      });
    }
  }

  Future<void> _uploadToFirebase() async {
    if (_csvData.length <= 1) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final headers = _csvData.first;
    final rows = _csvData.skip(1).toList();
    final total = rows.length;

    for (int i = 0; i < total; i++) {
      final row = rows[i];
      final data = <String, dynamic>{};

      for (int j = 0; j < headers.length && j < row.length; j++) {
        data[headers[j].toString()] = row[j];
      }

      final docRef =
          FirebaseFirestore.instance.collection('AssetRegister').doc();
      await docRef.set(data);

      setState(() {
        _uploadProgress = (i + 1) / total;
      });
    }

    setState(() {
      _isUploading = false;
      _csvData = [];
      _uploadProgress = 0.0;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bulk upload successful!')));
  }

  @override
  @override
  Widget build(BuildContext context) {
    final rowCount = _csvData.length > 1 ? _csvData.length - 1 : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Upload Assets')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _pickCSV,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select CSV File'),
              ),
              const SizedBox(height: 16),
              if (_csvData.isNotEmpty) ...[
                Text(
                  'Preview ($rowCount rows to upload):',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns:
                            _csvData.first
                                .map(
                                  (col) =>
                                      DataColumn(label: Text(col.toString())),
                                )
                                .toList(),
                        rows:
                            _csvData
                                .skip(1)
                                .map(
                                  (row) => DataRow(
                                    cells:
                                        row
                                            .map(
                                              (cell) => DataCell(
                                                Text(cell.toString()),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isUploading) ...[
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(0)}% Uploaded',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploadToFirebase,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload to Firebase'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
