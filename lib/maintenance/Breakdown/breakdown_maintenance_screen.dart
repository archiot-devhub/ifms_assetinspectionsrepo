import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BreakdownReportsScreen extends StatefulWidget {
  const BreakdownReportsScreen({Key? key}) : super(key: key);

  @override
  State<BreakdownReportsScreen> createState() => _BreakdownReportsScreenState();
}

class _BreakdownReportsScreenState extends State<BreakdownReportsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> breakdowns = [];
  List<Map<String, dynamic>> filteredBreakdowns = [];
  String searchQuery = '';

  final _searchController = TextEditingController();

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
          snapshot.docs
              .map(
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList();

      setState(() {
        breakdowns = list;
        onSearchChanged(); // filter on updated list
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading breakdown reports: $e')),
      );
    }
  }

  Future<void> _showReportDialog() async {
    final _formKey = GlobalKey<FormState>();
    String description = '';
    String maintStatus = 'Pending';
    String remarks = '';
    String severity = 'High';
    String project = '';
    String assetId = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Breakdown'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Asset ID',
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter Asset ID'
                                    : null,
                        onChanged: (val) => assetId = val,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Project'),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter Project'
                                    : null,
                        onChanged: (val) => project = val,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 2,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter Description'
                                    : null,
                        onChanged: (val) => description = val,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Remarks'),
                        maxLines: 2,
                        onChanged: (val) => remarks = val,
                      ),
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
                            (val) =>
                                setState(() => maintStatus = val ?? 'Pending'),
                      ),
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
                            (val) => setState(() => severity = val ?? 'High'),
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
                child: const Text('Submit'),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  Navigator.pop(context); // close dialog first

                  final now = DateTime.now();

                  try {
                    await FirebaseFirestore.instance
                        .collection('BreakdownReports')
                        .add({
                          'Description': description,
                          'Maintenancestatus': maintStatus,
                          'Remarks': remarks,
                          'Severity': severity,
                          'project': project,
                          'AssetID': assetId,
                          'ReportedDateTime': now,
                          'Reportedby':
                              'Technician', // Replace with actual logged in user if available
                          'Approvedby': '',
                          'BreakdownID': 'BR${now.millisecondsSinceEpoch}',
                        });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Breakdown reported successfully!'),
                      ),
                    );

                    fetchBreakdowns(); // Refresh list
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

  String formatReportedDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp)
      return DateFormat('dd-MM-yyyy HH:mm').format(date.toDate());
    if (date is DateTime) return DateFormat('dd-MM-yyyy HH:mm').format(date);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakdown Reports'),
        centerTitle: true,
        elevation: 1,
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
                  onPressed: _showReportDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Report Breakdown"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
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
                            String project = b['project'] ?? '';
                            String breakdownId = b['BreakdownID'] ?? '';
                            String description = b['Description'] ?? '';
                            String status = b['Maintenancestatus'] ?? '';
                            String reportedDt = formatReportedDate(
                              b['ReportedDateTime'],
                            );
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                status == 'Completed'
                                                    ? Colors.green.withOpacity(
                                                      0.10,
                                                    )
                                                    : status == 'In Progress'
                                                    ? Colors.orange.withOpacity(
                                                      0.10,
                                                    )
                                                    : Colors.blue.withOpacity(
                                                      0.10,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  status == 'Completed'
                                                      ? Colors.green
                                                      : status == 'In Progress'
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
                                        Text(
                                          breakdownId,
                                          style: const TextStyle(fontSize: 13),
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
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
}
