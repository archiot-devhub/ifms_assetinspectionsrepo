import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MaintenanceDetailsPPMScreen extends StatefulWidget {
  final String assetID;
  final String assetName;

  const MaintenanceDetailsPPMScreen({
    Key? key,
    required this.assetID,
    required this.assetName,
  }) : super(key: key);

  @override
  State<MaintenanceDetailsPPMScreen> createState() =>
      _MaintenanceDetailsPPMScreenState();
}

class _MaintenanceDetailsPPMScreenState
    extends State<MaintenanceDetailsPPMScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime monthStart = DateTime(_displayMonth.year, _displayMonth.month, 1);
    DateTime monthEnd = DateTime(
      _displayMonth.year,
      _displayMonth.month + 1,
      0,
      23,
      59,
      59,
    );
    DateTime today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asset Info display
              Text(
                'Asset ID: ${widget.assetID}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                'Asset Name: ${widget.assetName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              // Month navigation row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_displayMonth),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Calendar and maintenance data
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('MaintenanceSchedules')
                          .where('assetID', isEqualTo: widget.assetID)
                          .where(
                            'scheduleddate',
                            isGreaterThanOrEqualTo: Timestamp.fromDate(
                              monthStart,
                            ),
                          )
                          .where(
                            'scheduleddate',
                            isLessThanOrEqualTo: Timestamp.fromDate(monthEnd),
                          )
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    final Map<String, Map<String, dynamic>> dateStatusMap = {};
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final d = (data['scheduleddate'] as Timestamp?)?.toDate();
                      if (d == null) continue;
                      final dateStr = DateFormat('yyyy-MM-dd').format(d);
                      dateStatusMap[dateStr] = {
                        'status': (data['status'] ?? 'Scheduled'),
                        'doc': data,
                      };
                    }

                    int daysInMonth = DateUtils.getDaysInMonth(
                      _displayMonth.year,
                      _displayMonth.month,
                    );
                    DateTime firstOfMonth = DateTime(
                      _displayMonth.year,
                      _displayMonth.month,
                      1,
                    );
                    int weekDayStart = firstOfMonth.weekday % 7;

                    final List<Widget> gridTiles = [];
                    // Add padding tiles for days before month starts
                    for (int i = 0; i < weekDayStart; i++) {
                      gridTiles.add(const Expanded(child: SizedBox()));
                    }
                    // Create day tiles
                    for (int day = 1; day <= daysInMonth; day++) {
                      DateTime dayDate = DateTime(
                        _displayMonth.year,
                        _displayMonth.month,
                        day,
                      );
                      String dateStr = DateFormat('yyyy-MM-dd').format(dayDate);

                      Color? statusColor;
                      String? tooltip;
                      if (dateStatusMap.containsKey(dateStr)) {
                        final status =
                            (dateStatusMap[dateStr]!['status'] as String)
                                .toLowerCase();
                        if (status == 'completed') {
                          statusColor = Colors.green;
                          tooltip = 'Completed';
                        } else if (status == 'delayed') {
                          statusColor = Colors.orange;
                          tooltip = 'Delayed';
                        } else if (status == 'scheduled') {
                          statusColor = Colors.blue;
                          tooltip = 'Scheduled';
                        } else {
                          statusColor = Colors.grey;
                          tooltip = status.capitalize();
                        }
                      }

                      gridTiles.add(
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (dateStatusMap.containsKey(dateStr)) {
                                final data = dateStatusMap[dateStr]!['doc'];
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(22),
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  builder:
                                      (ctx) => _MaintenanceDetailBottomSheet(
                                        date: dayDate,
                                        data: data,
                                        assetID: widget.assetID,
                                      ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No maintenance scheduled on this date.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Tooltip(
                              message: tooltip ?? '',
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: statusColor?.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor ?? Colors.transparent,
                                    ),
                                  ),
                                  height: 32,
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            statusColor != null
                                                ? Colors.white
                                                : Colors.grey.shade800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    // Add padding tiles to complete final row of calendar if needed
                    int remainder = gridTiles.length % 7;
                    if (remainder != 0) {
                      int toAdd = 7 - remainder;
                      for (int i = 0; i < toAdd; i++) {
                        gridTiles.add(const Expanded(child: SizedBox()));
                      }
                    }

                    // Group tiles into rows of 7 days
                    List<Widget> rows = [];
                    for (int i = 0; i < gridTiles.length; i += 7) {
                      rows.add(Row(children: gridTiles.sublist(i, i + 7)));
                    }

                    // Weekday labels row
                    final weekLabels = List.generate(7, (i) {
                      final weekday = DateFormat.E().format(
                        DateTime(2024, 8, i + 4),
                      );
                      return Expanded(
                        child: Center(
                          child: Text(
                            weekday.substring(0, 2),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    });

                    return Column(
                      children: [
                        Row(children: weekLabels),
                        const SizedBox(height: 4),
                        ...rows,
                        const SizedBox(height: 16),

                        // New Section: Upcoming Maintenance Activities
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Upcoming Maintenance Activities',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('MaintenanceSchedules')
                                    .where('assetID', isEqualTo: widget.assetID)
                                    .where(
                                      'scheduleddate',
                                      isGreaterThanOrEqualTo:
                                          Timestamp.fromDate(
                                            DateTime(
                                              today.year,
                                              today.month,
                                              today.day,
                                            ),
                                          ),
                                    )
                                    .orderBy('scheduleddate', descending: false)
                                    .snapshots(),
                            builder: (context, upcomingSnapshot) {
                              if (upcomingSnapshot.hasError) {
                                return Text('Error: ${upcomingSnapshot.error}');
                              }
                              if (!upcomingSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final upcomingDocs = upcomingSnapshot.data!.docs;
                              if (upcomingDocs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No upcoming maintenance activities found.',
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: upcomingDocs.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item =
                                      upcomingDocs[index].data()
                                          as Map<String, dynamic>;
                                  final DateTime? scheduledDate =
                                      (item['scheduleddate'] as Timestamp?)
                                          ?.toDate();
                                  final status = item['status'] ?? '-';
                                  final planname = item['planname'] ?? '-';

                                  final dateText =
                                      scheduledDate != null
                                          ? DateFormat(
                                            'dd MMM yyyy',
                                          ).format(scheduledDate)
                                          : '-';

                                  Color statusColor = Colors.grey;
                                  switch (status.toString().toLowerCase()) {
                                    case 'completed':
                                      statusColor = Colors.green;
                                      break;
                                    case 'delayed':
                                      statusColor = Colors.orange;
                                      break;
                                    case 'scheduled':
                                      statusColor = Colors.blue;
                                      break;
                                  }

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                    ),
                                    title: Text(
                                      planname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Text('Scheduled Date: $dateText'),
                                    trailing: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MaintenanceDetailBottomSheet extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic> data;
  final String assetID;

  const _MaintenanceDetailBottomSheet({
    required this.date,
    required this.data,
    required this.assetID,
  });

  String _formatDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = _formatDate(date);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 6,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(
                DateFormat('dd MMMM yyyy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              _detailRow('Performed By', data['performedby'] ?? '-'),
              _detailRow('Status', data['status'] ?? '-'),
              _detailRow(
                'Notes',
                (data['remark']?.toString().trim().isNotEmpty ?? false)
                    ? data['remark']
                    : 'No issue found',
              ),
              _detailRow('Attachments', data['attachments'] ?? '-'),
              const SizedBox(height: 20),

              const Divider(thickness: 1),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Submitted Checkpoints',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),

              // StreamBuilder to load submitted checkpoints filtered by assetID & date
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('PPMmaintenanceresponses')
                        .where('assetID', isEqualTo: assetID)
                        .where(
                          'submittedon',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                            DateTime(date.year, date.month, date.day, 0, 0, 0),
                          ),
                        )
                        .where(
                          'submittedon',
                          isLessThanOrEqualTo: Timestamp.fromDate(
                            DateTime(
                              date.year,
                              date.month,
                              date.day,
                              23,
                              59,
                              59,
                            ),
                          ),
                        )
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error loading checkpoints: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      'No checkpoints submitted for this date.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final checkpointData =
                          docs[index].data() as Map<String, dynamic>;
                      final checkpoint = checkpointData['checkpoint'] ?? '-';
                      final response = checkpointData['response'] ?? '-';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checkpoint,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            response.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$title :",
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// String extension for capitalizing first letter
extension StringCap on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
