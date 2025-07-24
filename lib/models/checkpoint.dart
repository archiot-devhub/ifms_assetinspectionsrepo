import 'dart:io';

class Checkpoint {
  final String checkpointID;
  final String checkpoint;
  final String inputType;
  String? response;
  String? remarks;
  File? image;
  String? submittedBy; // ✅ New field

  Checkpoint({
    required this.checkpointID,
    required this.checkpoint,
    required this.inputType,
    this.response,
    this.remarks,
    this.image,
    this.submittedBy, // ✅ Include in constructor
  });

  // Factory constructor to create from Firestore
  factory Checkpoint.fromFirestore(Map<String, dynamic> data) {
    return Checkpoint(
      checkpointID: data['checkpointID'] ?? '',
      checkpoint: data['checkpoint'] ?? '',
      inputType: data['inputType'] ?? 'radio',
      response: data['response'], // Optional: in case it's being fetched
      remarks: data['remarks'], // Optional
      submittedBy: data['submittedBy'], // ✅ New field from Firestore
    );
  }

  // For local debugging or reuse (optional)
  Map<String, dynamic> toMap() {
    return {
      'checkpointID': checkpointID,
      'checkpoint': checkpoint,
      'inputType': inputType,
      'response': response,
      'remarks': remarks,
      'submittedBy': submittedBy, // ✅ Include in map for Firestore write
      // 'image' is not stored in Firestore
    };
  }
}
