import 'dart:io';

class Checkpoint {
  final String checkpointID;
  final String checkpoint;
  final String inputType;
  String? response;
  String? remarks;
  File? image;

  Checkpoint({
    required this.checkpointID,
    required this.checkpoint,
    required this.inputType,
    this.response,
    this.remarks,
    this.image,
  });

  // Factory constructor to create from Firestore
  factory Checkpoint.fromFirestore(Map<String, dynamic> data) {
    return Checkpoint(
      checkpointID: data['checkpointID'] ?? '',
      checkpoint: data['checkpoint'] ?? '',
      inputType: data['inputType'] ?? 'radio',
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
      // 'image' is excluded from this map; it's stored in Firebase Storage
    };
  }
}
