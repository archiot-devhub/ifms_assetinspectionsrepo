import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'asset_dashboard_screen.dart';

class AllAssetsTimelineScreen extends StatefulWidget {
  const AllAssetsTimelineScreen({super.key});

  @override
  State<AllAssetsTimelineScreen> createState() =>
      _AllAssetsTimelineScreenState();
}

class _AllAssetsTimelineScreenState extends State<AllAssetsTimelineScreen> {
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> assets = [];
  Map<String, List<Map<String, dynamic>>> assetPPMs = {};
  String searchTerm = '';

  @override
  void initState() {
    super.initState();
    loadAssetsWithPPMs();
  }

  Future<void> loadAssetsWithPPMs() async {
    try {
      final assetsSnapshot =
          await FirebaseFirestore.instance
              .collection('AssetRegister')
              .orderBy('installationdate')
              .get();
      assets = assetsSnapshot.docs.map((doc) => doc.data()).toList();

      final ppmSnapshot =
          await FirebaseFirestore.instance
              .collection('MaintenanceSchedules')
              .orderBy('scheduleddate')
              .get();
      final allPPMs = ppmSnapshot.docs.map((doc) => doc.data()).toList();

      assetPPMs.clear();
      for (final ppm in allPPMs) {
        final assetID = (ppm['assetID'] ?? '').toString();
        if (assetID.isEmpty) continue;
        assetPPMs.putIfAbsent(assetID, () => []);
        assetPPMs[assetID]!.add(ppm);
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      isLoading = false;
    });
  }

  Color ppmStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'delayed':
      case 'overdue':
        return Colors.red;
      case 'scheduled':
      default:
        return Colors.blue;
    }
  }

  String prettyDate(dynamic val) {
    if (val is Timestamp) return DateFormat('dd MMM yyyy').format(val.toDate());
    if (val is DateTime) return DateFormat('dd MMM yyyy').format(val);
    return val?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssets =
        assets.where((a) {
          final id = (a['assetID'] ?? '').toString().toLowerCase();
          final name = (a['assetname'] ?? '').toString().toLowerCase();
          final search = searchTerm.trim().toLowerCase();
          return id.contains(search) || name.contains(search);
        }).toList();

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
            title: const Text("Assets Maintenance Timeline"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white), // Icons color
            titleTextStyle: const TextStyle(
              color: Colors.white, // Title color
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssetDashboardScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ),

      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : (error != null
                  ? Center(child: Text("Error: $error"))
                  : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by Asset ID or Name',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (val) => setState(() => searchTerm = val),
                        ),
                      ),
                      Expanded(
                        child:
                            filteredAssets.isEmpty
                                ? const Center(child: Text('No assets found.'))
                                : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filteredAssets.length,
                                  itemBuilder: (ctx, idx) {
                                    final asset = filteredAssets[idx];
                                    final assetID = asset['assetID'] ?? '';
                                    final ppms = assetPPMs[assetID] ?? [];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 18),
                                      elevation: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _assetSummary(asset),
                                            const SizedBox(height: 12),
                                            _timelineBox(asset, ppms, context),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  )),
    );
  }

  Widget _assetSummary(Map<String, dynamic> data) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
          data['imageUrl'] != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['imageUrl'],
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              )
              : const Icon(Icons.broken_image, size: 36),
      title: Text(
        data['assetname'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: ${data['assetID'] ?? ''}',
            style: const TextStyle(fontSize: 12),
          ),
          if (data['assetgroup'] != null)
            Text(
              'Group: ${data['assetgroup'] ?? ""}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _timelineBox(
    Map asset,
    List<Map<String, dynamic>> ppmEvents,
    BuildContext context,
  ) {
    DateTime? install, elapsed;
    try {
      install = (asset['installationdate'] as Timestamp?)?.toDate();
      elapsed = (asset['elapsedlife'] as Timestamp?)?.toDate();
    } catch (_) {}
    if (install == null || elapsed == null) {
      return const Text("Timeline not available.");
    }

    final sortedPPMs = List<Map<String, dynamic>>.from(ppmEvents)..sort((a, b) {
      final dtA = (a['scheduleddate'] as Timestamp).toDate();
      final dtB = (b['scheduleddate'] as Timestamp).toDate();
      return dtA.compareTo(dtB);
    });
    final nEvents = sortedPPMs.length;

    // We'll distribute all events plus install and elapsed (nEvents + 2 markers) across the row
    final timelineMarkers = <Widget>[];

    // INSTALL marker (left)
    timelineMarkers.add(
      _timelineMarker(
        icon: Icons.flag,
        color: Colors.black,
        label: "Install\n${prettyDate(install)}",
        smallIcon: true,
      ),
    );

    // Timeline segments (divide total width evenly by number of slots)
    for (int i = 0; i < nEvents || i == 0; i++) {
      if (i < nEvents) {
        // Add connecting bar before each PPM except just after install
        timelineMarkers.add(_timelineConnectingBar());
        // PPM event dot
        final ppm = sortedPPMs[i];
        String ppmStatus = (ppm['status'] ?? 'scheduled').toString();
        Color dotColor = ppmStatusColor(ppmStatus);
        timelineMarkers.add(
          _timelineMarker(
            dotColor: dotColor,
            label: prettyDate((ppm['scheduleddate'] as Timestamp).toDate()),
            onTap: () => _showPPMDialog(context, ppm),
          ),
        );
      }
    }

    // Connect last event (or install) to elapsed
    timelineMarkers.add(_timelineConnectingBar());

    // ELAPSED marker (right)
    timelineMarkers.add(
      _timelineMarker(
        icon: Icons.timeline,
        color: Colors.teal,
        label: "EOL\n${prettyDate(elapsed)}",
        smallIcon: true,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: timelineMarkers,
      ),
    );
  }

  Widget _timelineConnectingBar() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: Colors.grey[300],
      ),
    );
  }

  // For install/elapsed, small icon; for PPM, colored dot
  Widget _timelineMarker({
    IconData? icon,
    Color? color,
    Color? dotColor,
    required String label,
    bool smallIcon = false,
    VoidCallback? onTap,
  }) {
    Widget marker;
    if (icon != null) {
      marker = CircleAvatar(
        radius: smallIcon ? 14 : 16,
        backgroundColor: color ?? Colors.grey[400],
        child: Icon(icon, color: Colors.white, size: smallIcon ? 15 : 17),
      );
    } else {
      // Small colored dot for PPM
      marker = GestureDetector(
        onTap: onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor ?? Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(height: 5),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showPPMDialog(BuildContext context, Map<String, dynamic> ppm) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(ppm['planname'] ?? 'Maintenance Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ppm['instructions'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('Instructions: ${ppm['instructions']}'),
                    ),
                  if (ppm['scheduleddate'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        'Scheduled: ${prettyDate(ppm['scheduleddate'])}',
                      ),
                    ),
                  if (ppm['completedon'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        'Completed: ${prettyDate(ppm['completedon'])}',
                      ),
                    ),
                  if (ppm['status'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text('Status: ${ppm['status']}'),
                    ),
                  if (ppm['assignedto'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text('Assigned to: ${ppm['assignedto']}'),
                    ),
                  if (ppm['frequency'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text('Frequency: ${ppm['frequency']}'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
