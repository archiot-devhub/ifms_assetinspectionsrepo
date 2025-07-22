import '../models/inspection_model.dart';

final List<Inspection> mockInspections = [
  Inspection(
    logId: 1340,
    project: 'Vector, Pune',
    assetId: 'VTP-T3-TR-Z1-WCC-01',
    assetName: 'Water Cooled Chiller',
    checklistId: 'CL014',
    checkingDate: DateTime(2025, 7, 10),
    status: 'Not Submitted',
    checkedBy: 'Ramesh',
  ),
  Inspection(
    logId: 1341,
    project: 'Vector, Pune',
    assetId: 'VTP-T3-TR-Z1-WCC-01',
    assetName: 'Water Cooled Chiller',
    checklistId: 'CL014',
    checkingDate: DateTime(2025, 8, 10),
    status: 'Not Submitted',
    checkedBy: 'Ramesh',
  ),
  Inspection(
    logId: 1345,
    project: 'Vector, Pune',
    assetId: 'VTP-T3-TR-Z1-WCC-01',
    assetName: 'Water Cooled Chiller',
    checklistId: 'CL014',
    checkingDate: DateTime(2025, 7, 13),
    status: 'Submitted',
    checkedBy: 'Ramesh',
  ),
  // Add more as needed
];
