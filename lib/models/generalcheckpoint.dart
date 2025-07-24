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

  factory Checkpoint.fromFirestore(Map<String, dynamic> data) {
    return Checkpoint(
      checkpointID: data['checkpointID'] ?? '',
      checkpoint: data['checkpoint'] ?? '',
      inputType: data['inputType'] ?? 'text',
    );
  }
}
