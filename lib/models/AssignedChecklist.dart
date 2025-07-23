import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedChecklist {
  final String inspectionId;
  final String assetId;
  final String assetName;
  final DateTime scheduledDate;
  final String status;
  final String checkedBy;

  AssignedChecklist({
    required this.inspectionId,
    required this.assetId,
    required this.assetName,
    required this.scheduledDate,
    required this.status,
    required this.checkedBy,
  });

  factory AssignedChecklist.fromMap(Map<String, dynamic> map) {
    return AssignedChecklist(
      inspectionId: map['inspectionId'] ?? '',
      assetId: map['assetId'] ?? '',
      assetName: map['assetName'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      status: map['status'] ?? '',
      checkedBy: map['checkedBy'] ?? '',
    );
  }
}
