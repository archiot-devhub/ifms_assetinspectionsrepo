import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'breakdown_mobilescanner_screen.dart'; // Make sure you have this file for QR scanning

class BreakdownReportsScreen extends StatefulWidget {
  const BreakdownReportsScreen({super.key});

  @override
  State<BreakdownReportsScreen> createState() => _BreakdownReportsScreenState();
}

class _BreakdownReportsScreenState extends State<BreakdownReportsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> breakdowns = [];
  List<Map<String, dynamic>> filteredBreakdowns = [];
  String searchQuery = '';

  final _searchController = TextEditingController();

  static const String fixedProjectName = "Vector, Pune";

  @override
  void initState() {
    super.initState();
    fetchBreakdowns();
    _searchController.addListener(onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredBreakdowns =
          breakdowns.where((b) {
            final assetId = (b['AssetID'] ?? '').toString().toLowerCase();
            final project = (b['project'] ?? '').toString().toLowerCase();
            final description =
                (b['Description'] ?? '').toString().toLowerCase();
            return assetId.contains(query) ||
                project.contains(query) ||
                description.contains(query);
          }).toList();
    });
  }

  Future<void> fetchBreakdowns() async {
    setState(() => isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('BreakdownReports')
              .orderBy('ReportedDateTime', descending: true)
              .get();
      final list =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      setState(() {
        breakdowns = List<Map<String, dynamic>>.from(list);
        onSearchChanged();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading breakdown reports: $e')),
      );
    }
  }

  String formatReportedDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('dd-MM-yyyy HH:mm').format(date.toDate());
    }
    if (date is DateTime) return DateFormat('dd-MM-yyyy HH:mm').format(date);
    return '';
  }

  Future<void> _showReportDialog({Map<String, dynamic>? existingData}) async {
    final formKey = GlobalKey<FormState>();

    final assetIdController = TextEditingController(
      text: existingData?['AssetID'] ?? '',
    );
    String project = fixedProjectName;
    String description = existingData?['Description'] ?? '';
    String severity = existingData?['Severity'] ?? 'High';
    String maintStatus = existingData?['Maintenancestatus'] ?? 'Pending';
    String remarks = existingData?['Remarks'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existingData == null ? 'Report Breakdown' : 'Update Breakdown',
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AssetID: Text input with Scan button only in report mode
                      if (existingData == null)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: assetIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Asset ID',
                                ),
                                validator:
                                    (val) =>
                                        val == null || val.isEmpty
                                            ? 'Enter Asset ID'
                                            : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_scanner, size: 20),
                              label: const Text('Scan Asset ID'),
                              onPressed: () async {
                                final scanned = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const MobileScannerScreen(),
                                  ),
                                );
                                if (scanned != null && scanned.isNotEmpty) {
                                  setState(() {
                                    assetIdController.text = scanned;
                                  });
                                }
                              },
                            ),
                          ],
                        )
                      else
                        // Read-only AssetID in update mode
                        TextFormField(
                          initialValue: assetIdController.text,
                          decoration: const InputDecoration(
                            labelText: 'Asset ID',
                          ),
                          enabled: false,
                        ),

                      const SizedBox(height: 10),

                      // Project - always read-only to fixed value
                      TextFormField(
                        initialValue: project,
                        decoration: const InputDecoration(labelText: 'Project'),
                        enabled: false,
                      ),

                      const SizedBox(height: 10),

                      // Description
                      TextFormField(
                        initialValue: description,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                        ),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        minLines: 3,
                        enabled: existingData == null, // read-only in update
                        validator:
                            (val) =>
                                (val == null || val.isEmpty)
                                    ? 'Enter Description'
                                    : null,
                        onChanged: (val) {
                          if (existingData == null) description = val;
                        },
                      ),

                      const SizedBox(height: 10),

                      // Severity dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Severity',
                        ),
                        value: severity,
                        items:
                            ['High', 'Medium', 'Low']
                                .map(
                                  (level) => DropdownMenuItem(
                                    value: level,
                                    child: Text(level),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            existingData == null
                                ? (val) =>
                                    setState(() => severity = val ?? severity)
                                : null,
                        disabledHint: Text(severity),
                      ),

                      const SizedBox(height: 10),

                      // Maintenance Status dropdown - editable always
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Maintenance Status',
                        ),
                        value: maintStatus,
                        items:
                            ['Pending', 'Assigned', 'Resolved']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(
                              () => maintStatus = val ?? maintStatus,
                            ),
                      ),

                      const SizedBox(height: 10),

                      // Remarks field - editable always
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Remarks'),
                        maxLines: 2,
                        initialValue: remarks,
                        onChanged: (val) => remarks = val,
                      ),

                      const SizedBox(height: 15),

                      // Attach Relevant Documents only in report mode
                      if (existingData == null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Attach Relevant Documents'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Attachment feature not implemented yet',
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            SafeArea(
              child: TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SafeArea(
              child: ElevatedButton(
                child: Text(existingData == null ? 'Submit' : 'Update'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  if (existingData == null) {
                    // Check mandatory fields for new report
                    if (assetIdController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Asset ID cannot be empty'),
                        ),
                      );
                      return;
                    }
                    if (description.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Description cannot be empty'),
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.pop(context);

                  final now = DateTime.now();
                  final collection = FirebaseFirestore.instance.collection(
                    'BreakdownReports',
                  );

                  try {
                    if (existingData == null) {
                      await collection.add({
                        'AssetID': assetIdController.text.trim(),
                        'project': project,
                        'Description': description,
                        'Severity': severity,
                        'Maintenancestatus': maintStatus,
                        'Remarks': remarks,
                        'ReportedDateTime': now,
                        'Reportedby': 'Technician', // replace with actual user
                        'Approvedby': '',
                        'BreakdownID': 'BR${now.millisecondsSinceEpoch}',
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Breakdown reported successfully!'),
                        ),
                      );
                    } else {
                      // Update only Maintenance Status and Remarks during update
                      await collection.doc(existingData['id']).update({
                        'Maintenancestatus': maintStatus,
                        'Remarks': remarks,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Breakdown updated successfully!'),
                        ),
                      );
                    }
                    fetchBreakdowns();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit: $e')),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
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
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            title: const Text('Breakdown Reports'),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // Search box
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Asset ID, Project or Description',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReportDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Report Breakdown"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchBreakdowns,
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredBreakdowns.isEmpty
                          ? const Center(
                            child: Text('No breakdown reports found.'),
                          )
                          : ListView.builder(
                            itemCount: filteredBreakdowns.length,
                            itemBuilder: (context, idx) {
                              final b = filteredBreakdowns[idx];
                              final project = b['project'] ?? '';
                              final breakdownId = b['BreakdownID'] ?? '';
                              final description = b['Description'] ?? '';
                              final status = b['Maintenancestatus'] ?? '';
                              final reportedDt = formatReportedDate(
                                b['ReportedDateTime'],
                              );
                              final assetId = b['AssetID'] ?? '';
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 7,
                                  horizontal: 2,
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.home_repair_service,
                                            size: 19,
                                            color: Colors.blueAccent,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              project,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  status == 'Resolved'
                                                      ? Colors.green
                                                          .withOpacity(0.10)
                                                      : status == 'Assigned'
                                                      ? Colors.orange
                                                          .withOpacity(0.10)
                                                      : Colors.blue.withOpacity(
                                                        0.10,
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    status == 'Resolved'
                                                        ? Colors.green
                                                        : status == 'Assigned'
                                                        ? Colors.orange[700]
                                                        : Colors.blue[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Text(
                                            "ID: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              breakdownId,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "AssetID: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              assetId,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Desc: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              description,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            reportedDt,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: () {
                                              _showReportDialog(
                                                existingData: b,
                                              );
                                            },
                                            child: const Text('Update'),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
