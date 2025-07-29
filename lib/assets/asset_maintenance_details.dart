import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MaintenanceDetailsPPMScreen extends StatelessWidget {
  final String assetID;
  final String assetName; // for the AppBar

  const MaintenanceDetailsPPMScreen({
    super.key,
    required this.assetID,
    required this.assetName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PPM Schedules – $assetName')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('MaintenanceSchedules')
                  .where('assetID', isEqualTo: assetID)
                  .orderBy('scheduleddate')
                  .snapshots(),
          builder: (context, snapshot) {
            // Debug prints (remove in production)
            print('Connection state: ${snapshot.connectionState}');
            if (snapshot.hasError) {
              print('Error: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('Waiting for data...');
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('No maintenance schedules found');
              return const Center(
                child: Text('No maintenance schedules found.'),
              );
            }
            print('Got ${snapshot.data!.docs.length} schedules');

            final scheduleDocs = snapshot.data!.docs;

            // Map dates to status and doc for quick lookup
            final Map<String, Map<String, dynamic>> dateStatusMap = {};
            for (final doc in scheduleDocs) {
              final data = doc.data() as Map<String, dynamic>;
              DateTime scheduled =
                  (data['scheduleddate'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              String dateStr = DateFormat('yyyy-MM-dd').format(scheduled);

              dateStatusMap[dateStr] = {
                'status': data['status'] ?? 'Scheduled',
                'doc': data,
              };
            }

            final now = DateTime.now();
            final calendarMonth = DateTime(now.year, now.month);
            final firstDayOfMonth = DateTime(
              calendarMonth.year,
              calendarMonth.month,
              1,
            );
            final daysInMonth = DateUtils.getDaysInMonth(
              calendarMonth.year,
              calendarMonth.month,
            );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Month title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(calendarMonth),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Weekday headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final weekday = DateFormat.E().format(
                        DateTime(2024, 8, i + 4),
                      );
                      return Expanded(
                        child: Center(
                          child: Text(
                            weekday.substring(0, 2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  // Calendar grid
                  Expanded(
                    child: _CalendarGrid(
                      calendarMonth: calendarMonth,
                      daysInMonth: daysInMonth,
                      dateStatusMap: dateStatusMap,
                      firstDayOfMonth: firstDayOfMonth,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Legend
                  Row(
                    children: [
                      _legendDot(Colors.green),
                      const SizedBox(width: 4),
                      const Text('Completed'),
                      const SizedBox(width: 16),
                      _legendDot(Colors.orange),
                      const SizedBox(width: 4),
                      const Text('Delayed'),
                      const SizedBox(width: 16),
                      _legendDot(Colors.blue),
                      const SizedBox(width: 4),
                      const Text('Scheduled'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Upcoming/recent PPMs list
                  _PPMList(scheduleDocs: scheduleDocs),
                ],
              ),
            );
          },
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

class _CalendarGrid extends StatelessWidget {
  final DateTime calendarMonth;
  final int daysInMonth;
  final Map<String, Map<String, dynamic>> dateStatusMap;
  final DateTime firstDayOfMonth;

  const _CalendarGrid({
    required this.calendarMonth,
    required this.daysInMonth,
    required this.dateStatusMap,
    required this.firstDayOfMonth,
  });

  @override
  Widget build(BuildContext context) {
    final int weekDayStart = firstDayOfMonth.weekday % 7;

    final List<Widget> gridTiles = [];

    for (int i = 0; i < weekDayStart; i++) {
      gridTiles.add(const Expanded(child: SizedBox()));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime dayDate = DateTime(calendarMonth.year, calendarMonth.month, day);
      String dateStr = DateFormat('yyyy-MM-dd').format(dayDate);

      Color baseColor = Colors.grey.shade200;
      String? tooltip;

      if (dateStatusMap.containsKey(dateStr)) {
        final status =
            (dateStatusMap[dateStr]!['status'] as String).toLowerCase();
        if (status == 'completed') {
          baseColor = Colors.green;
          tooltip = 'Completed';
        } else if (status == 'delayed') {
          baseColor = Colors.orange;
          tooltip = 'Delayed';
        } else if (status == 'scheduled') {
          baseColor = Colors.blue;
          tooltip = 'Scheduled';
        } else {
          baseColor = Colors.blueGrey;
          tooltip = status.capitalize();
        }
      }

      Widget statusDot = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color:
              dateStatusMap.containsKey(dateStr)
                  ? baseColor.withOpacity(0.88)
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  dateStatusMap.containsKey(dateStr)
                      ? Colors.white
                      : Colors.grey.shade800,
            ),
          ),
        ),
      );

      gridTiles.add(
        Expanded(
          child: Tooltip(
            message: tooltip ?? '',
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: statusDot,
            ),
          ),
        ),
      );
    }

    int remainder = gridTiles.length % 7;
    if (remainder != 0) {
      int toAdd = 7 - remainder;
      for (int i = 0; i < toAdd; i++) {
        gridTiles.add(const Expanded(child: SizedBox()));
      }
    }

    final List<Widget> rows = [];
    for (int i = 0; i < gridTiles.length; i += 7) {
      rows.add(Row(children: gridTiles.sublist(i, i + 7)));
    }

    return Column(children: rows);
  }
}

class _PPMList extends StatelessWidget {
  final List<QueryDocumentSnapshot> scheduleDocs;

  const _PPMList({required this.scheduleDocs});

  @override
  Widget build(BuildContext context) {
    if (scheduleDocs.isEmpty) return const SizedBox();

    final now = DateTime.now();
    final sorted =
        scheduleDocs..sort(
          (a, b) => ((a['scheduleddate'] as Timestamp).toDate()).compareTo(
            (b['scheduleddate'] as Timestamp).toDate(),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming/Recent PPMs",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        ...sorted.take(5).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['scheduleddate'] as Timestamp?)?.toDate();
          final status = (data['status'] ?? '').toString();
          final plan = data['planname'] ?? '';
          Color statusColor = Colors.blueGrey;
          if (status.toLowerCase() == 'completed') statusColor = Colors.green;
          if (status.toLowerCase() == 'delayed') statusColor = Colors.orange;
          if (status.toLowerCase() == 'scheduled') statusColor = Colors.blue;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(date ?? now),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plan,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// Helper extension to capitalize strings
extension StringCap on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();
}
