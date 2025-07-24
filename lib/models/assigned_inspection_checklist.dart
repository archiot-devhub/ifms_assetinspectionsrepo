import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedInspectionChecklist {
  final String inspectionID;
  final String locationID;
  final String assignedTo;
  final String? remarks;
  final DateTime scheduledDate;
  final String status;
  final DateTime? completedOn;
  final String category; // ✅ New field

  AssignedInspectionChecklist({
    required this.inspectionID,
    required this.locationID,
    required this.assignedTo,
    this.remarks,
    required this.scheduledDate,
    required this.status,
    this.completedOn,
    required this.category, // ✅ Add to constructor
  });

  factory AssignedInspectionChecklist.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return AssignedInspectionChecklist(
      inspectionID: data['inspectionID'] ?? '',
      locationID: data['LocationID'] ?? '',
      assignedTo: data['Assignedto'] ?? '',
      remarks: data['Remarks'],
      scheduledDate: (data['scheduleddate'] as Timestamp).toDate(),
      status: data['status'] ?? '',
      completedOn:
          data['completedon'] != null
              ? (data['completedon'] as Timestamp).toDate()
              : null,
      category: data['category'] ?? '-', // ✅ Default fallback
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inspectionID': inspectionID,
      'LocationID': locationID,
      'Assignedto': assignedTo,
      'Remarks': remarks,
      'scheduleddate': scheduledDate,
      'status': status,
      'completedon': completedOn,
      'category': category, // ✅ Add to map
    };
  }
}
