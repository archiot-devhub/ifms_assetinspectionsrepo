import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledPPM {
  final String docId; // Firestore document ID
  final String scheduleId; // Custom field in Firestore
  final String assetId;
  final String assetName;
  final String planName;
  final DateTime scheduledDate;
  final String status;
  final String project;

  ScheduledPPM({
    required this.docId,
    required this.scheduleId,
    required this.assetId,
    required this.assetName,
    required this.planName,
    required this.scheduledDate,
    required this.status,
    required this.project,
  });

  factory ScheduledPPM.fromMap(Map<String, dynamic> map, String docId) {
    return ScheduledPPM(
      docId: docId, // ← This is the document ID from Firestore
      scheduleId: map['scheduleid'] ?? '', // ← Custom field in document
      assetId: map['assetID'] ?? '',
      assetName: map['assetname'] ?? '',
      planName: map['planname'] ?? '',
      scheduledDate:
          map['scheduleddate'] is Timestamp
              ? (map['scheduleddate'] as Timestamp).toDate()
              : DateTime.tryParse(map['scheduleddate']?.toString() ?? '') ??
                  DateTime.now(),
      status: map['status'] ?? '',
      project: map['project'] ?? '',
    );
  }
}
