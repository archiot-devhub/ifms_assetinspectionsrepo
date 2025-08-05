// breakdown.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Breakdown {
  final String breakdownId;
  final String assetId;
  final String description;
  final String maintenanceStatus;
  final String remarks;
  final Timestamp reportedDateTime;
  final String reportedBy;
  final String approvedBy;
  final String severity;
  final String project;

  Breakdown({
    required this.breakdownId,
    required this.assetId,
    required this.description,
    required this.maintenanceStatus,
    required this.remarks,
    required this.reportedDateTime,
    required this.reportedBy,
    required this.approvedBy,
    required this.severity,
    required this.project,
  });

  factory Breakdown.fromMap(Map<String, dynamic> data, String? docId) {
    return Breakdown(
      breakdownId: data['BreakdownID'] ?? docId ?? '',
      assetId: data['AssetID'] ?? '',
      description: data['Description'] ?? '',
      maintenanceStatus: data['Maintenancestatus'] ?? '',
      remarks: data['Remarks'] ?? '',
      reportedDateTime: data['ReportedDateTime'] ?? Timestamp.now(),
      reportedBy: data['Reportedby'] ?? '',
      approvedBy: data['Approvedby'] ?? '',
      severity: data['Severity'] ?? '',
      project: data['project'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'BreakdownID': breakdownId,
      'AssetID': assetId,
      'Description': description,
      'Maintenancestatus': maintenanceStatus,
      'Remarks': remarks,
      'ReportedDateTime': reportedDateTime,
      'Reportedby': reportedBy,
      'Approvedby': approvedBy,
      'Severity': severity,
      'project': project,
    };
  }
}
