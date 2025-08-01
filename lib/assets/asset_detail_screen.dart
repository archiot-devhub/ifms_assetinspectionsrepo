import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'asset_maintenance_details.dart';

class AssetDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot assetData;

  const AssetDetailScreen({super.key, required this.assetData});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  // Control for each expansion tile (all true initially)
  final List<bool> _expandedSections = List.generate(5, (_) => true);

  // Define your condition and status lists here (should correspond to your app data)
  final List<String> conditionOptions = [
    'Working',
    'Breakdown',
    'Under Maintenance',
    'Degrading',
  ];

  final List<String> statusOptions = ['Active', 'Inactive'];

  @override
  Widget build(BuildContext context) {
    final assetImageUrl = widget.assetData.get('imageUrl') ?? '';
    // Hide original assetName to avoid confusion since header is fixed "View Asset"
    // final assetName = widget.assetData.get('assetname') ?? 'Asset Details';

    return Scaffold(
      appBar: AppBar(title: const Text('View Asset')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3-Button Row ("pills" style) - Removed Next Due, Update uses _showEditPopup now
              Row(
                children: [
                  _pillButton(
                    icon: Icons.loop,
                    label: "Maintenance",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MaintenanceDetailsPPMScreen(
                                assetID: widget.assetData.get('assetID') ?? '',
                                assetName:
                                    widget.assetData.get('assetname') ?? '',
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ), // Adjust width as needed for spacing
                  _pillButton(
                    icon: Icons.edit_note_rounded,
                    label: "Update",
                    onTap: () => _showEditPopup(widget.assetData),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Asset Gallery/Image and Details
              _collapsibleCard(
                context: context,
                index: 0,
                title: 'Basic Info',
                initiallyExpanded: _expandedSections[0],
                onExpansionChanged: (expanded) {
                  setState(() => _expandedSections[0] = expanded);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(
                            'Asset ID',
                            widget.assetData.get('assetID') ?? '',
                          ),
                          _infoRow(
                            'Asset Name',
                            widget.assetData.get('assetname') ?? '',
                          ),
                          _infoRow(
                            'Asset Group',
                            widget.assetData.get('assetgroup') ?? '',
                          ),
                          _infoRow(
                            'Condition',
                            widget.assetData.get('condition') ?? '',
                          ),
                          _infoRow(
                            'Status',
                            widget.assetData.get('status') ?? '',
                          ),
                        ],
                      ),
                    ),
                    if (assetImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            assetImageUrl,
                            width: 64,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _collapsibleCard(
                context: context,
                index: 1,
                title: 'Location & Assignment',
                initiallyExpanded: _expandedSections[1],
                onExpansionChanged: (expanded) {
                  setState(() => _expandedSections[1] = expanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      'Location',
                      widget.assetData.get('location') ?? '',
                    ),
                    _infoRow(
                      'Floor / Zone',
                      widget.assetData.get('floorzone') ?? '',
                    ),
                    _infoRow(
                      'Room / Area',
                      widget.assetData.get('roomarea') ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _collapsibleCard(
                context: context,
                index: 2,
                title: 'Technical / Manufacturer Info',
                initiallyExpanded: _expandedSections[2],
                onExpansionChanged: (expanded) {
                  setState(() => _expandedSections[2] = expanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      'Manufacturer',
                      widget.assetData.get('manufacturer') ?? '',
                    ),
                    _infoRow(
                      'Model',
                      widget.assetData.get('modelnumber') ?? '',
                    ),
                    _infoRow(
                      'Serial Number',
                      widget.assetData.get('serialnumber') ?? '',
                    ),
                    _infoRow(
                      'Technical Specs',
                      widget.assetData.get('technicalclassification') ?? '',
                    ),
                    _infoRow(
                      'Network Config',
                      widget.assetData.get('networkconfig') ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _collapsibleCard(
                context: context,
                index: 3,
                title: 'Lifecycle & Status Timeline',
                initiallyExpanded: _expandedSections[3],
                onExpansionChanged: (expanded) {
                  setState(() => _expandedSections[3] = expanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      'Purchase Date',
                      _formatDate(widget.assetData.get('purchasedate')),
                    ),
                    _infoRow(
                      'Installation Date',
                      _formatDate(widget.assetData.get('installationdate')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _collapsibleCard(
                context: context,
                index: 4,
                title: 'Attached Documents',
                initiallyExpanded: _expandedSections[4],
                onExpansionChanged: (expanded) {
                  setState(() => _expandedSections[4] = expanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    documentTile(
                      'Asset Manual',
                      widget.assetData.get('manualUrl') ?? '',
                    ),
                    documentTile(
                      'Warranty Certificate',
                      widget.assetData.get('warrantyUrl') ?? '',
                    ),
                    documentTile(
                      'Invoice',
                      widget.assetData.get('invoiceUrl') ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF004EFF), // Label/icon color
        side: const BorderSide(color: Color(0xFF004EFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  Widget _collapsibleCard({
    required BuildContext context,
    required int index,
    required String title,
    required Widget child,
    bool initiallyExpanded = false,
    required ValueChanged<bool> onExpansionChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF004EFF),
            ),
          ),
          maintainState: true,
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [child],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value.isNotEmpty) ? value : '-',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget documentTile(String title, String url) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing:
            url.trim().isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Open Document',
                  onPressed: () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                )
                : const Text(
                  'Not uploaded',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is Timestamp) {
      final dt = date.toDate();
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
    }
    if (date is DateTime) {
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
    return date.toString();
  }

  void _showEditPopup(DocumentSnapshot asset) {
    String condition = asset['condition'] ?? '';
    String status = asset['status'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Asset',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Asset ID: ${asset['assetID']}'),
                    Text('Asset Name: ${asset['assetname']}'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: condition,
                      items:
                          conditionOptions
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            condition = val;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Condition'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      items:
                          statusOptions
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            status = val;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('AssetRegister')
                              .doc(asset.id)
                              .update({
                                'condition': condition,
                                'status': status,
                                'modifiedTime': FieldValue.serverTimestamp(),
                              });
                          Navigator.pop(context);
                          setState(() {}); // Refresh screen after update
                        },
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
