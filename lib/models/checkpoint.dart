import 'dart:io';

class Checkpoint {
  final String checkpoint;
  final String inputType;
  String? response;
  String? remarks;
  File? image;

  Checkpoint({
    required this.checkpoint,
    required this.inputType,
    this.response,
    this.remarks,
    this.image,
  });

  // Factory constructor to create from Firestore
  factory Checkpoint.fromFirestore(Map<String, dynamic> data) {
    return Checkpoint(
      checkpoint: data['checkpoint'] ?? '',
      inputType: data['inputType'] ?? 'radio',
    );
  }

  // To save (if needed)
  Map<String, dynamic> toMap() {
    return {
      'checkpoint': checkpoint,
      'inputType': inputType,
      'response': response,
      'remarks': remarks,
      // image not included, needs upload to Firebase Storage
    };
  }
}
