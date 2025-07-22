class Inspection {
  final int logId;
  final String project;
  final String assetId;
  final String assetName;
  final String checklistId;
  final DateTime checkingDate;
  final String status;
  final String checkedBy;

  Inspection({
    required this.logId,
    required this.project,
    required this.assetId,
    required this.assetName,
    required this.checklistId,
    required this.checkingDate,
    required this.status,
    required this.checkedBy,
  });
}
