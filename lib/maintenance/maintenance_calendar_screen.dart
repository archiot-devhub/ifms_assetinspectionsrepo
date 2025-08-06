import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class MaintenanceCalendarScreen extends StatefulWidget {
  const MaintenanceCalendarScreen({super.key});

  @override
  State<MaintenanceCalendarScreen> createState() =>
      _MaintenanceCalendarScreenState();
}

class _MaintenanceCalendarScreenState extends State<MaintenanceCalendarScreen> {
  Map<DateTime, List<Map<String, dynamic>>> events = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('MaintenanceSchedules')
            .get();

    Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final DateTime date = (data['scheduleddate'] as Timestamp).toDate();
      final status = data['status'];
      final asset = data['assetname'] ?? 'Asset';
      final assetID = data['assetID'] ?? '';

      final day = DateTime(date.year, date.month, date.day); // normalize

      newEvents.putIfAbsent(day, () => []).add({
        'asset': asset,
        'assetID': assetID,
        'status': status,
      });
    }

    setState(() {
      events = newEvents;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Scheduled':
        return Colors.blue;
      case 'Delayed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004EFF), Color(0xFF002F99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ), // Icons are white
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ), // Title is white
            title: const Text('PPM Calendar View'),
          ),
        ),
      ),

      body: Column(
        children: [
          TableCalendar(
            focusedDay: focusedDay,
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return events[key] ?? [];
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // ❌ hide "2 weeks" button
            ),
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children:
                  (events[DateTime(
                            selectedDay?.year ?? 0,
                            selectedDay?.month ?? 0,
                            selectedDay?.day ?? 0,
                          )] ??
                          [])
                      .map(
                        (event) => ListTile(
                          leading: Icon(
                            Icons.build,
                            color: getStatusColor(event['status']),
                          ),
                          title: Text(
                            '${event['asset']} (${event['assetID']})',
                          ),
                          subtitle: Text('Status: ${event['status']}'),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
