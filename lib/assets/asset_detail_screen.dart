import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'asset_maintenance_details.dart';

class AssetDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot assetData;

  const AssetDetailScreen({super.key, required this.assetData});

  @override
  Widget build(BuildContext context) {
    final assetImageUrl = assetData.get('imageUrl') ?? '';
    final assetName = assetData.get('assetname') ?? 'Asset Details';

    return Scaffold(
      appBar: AppBar(title: Text(assetName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _collapsibleCard(
                context,
                title: 'Basic Info',
                initiallyExpanded: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Key Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Asset ID', assetData.get('assetID') ?? ''),
                          _infoRow(
                            'Asset Name',
                            assetData.get('assetname') ?? '',
                          ),
                          _infoRow(
                            'Asset Group',
                            assetData.get('assetgroup') ?? '',
                          ),
                          _infoRow(
                            'Condition',
                            assetData.get('condition') ?? '',
                          ),
                          _infoRow('Status', assetData.get('status') ?? ''),
                        ],
                      ),
                    ),
                    // Image (smaller, rounded corners)
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
                context,
                title: 'Location & Assignment',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Location', assetData.get('location') ?? ''),
                    _infoRow('Floor / Zone', assetData.get('floorzone') ?? ''),
                    _infoRow('Room / Area', assetData.get('roomarea') ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _collapsibleCard(
                context,
                title: 'Technical / Manufacturer Info',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      'Manufacturer',
                      assetData.get('manufacturer') ?? '',
                    ),
                    _infoRow('Model', assetData.get('modelnumber') ?? ''),
                    _infoRow(
                      'Serial Number',
                      assetData.get('serialnumber') ?? '',
                    ),
                    _infoRow(
                      'Technical Specs',
                      assetData.get('technicalclassification') ?? '',
                    ),
                    _infoRow(
                      'Network Config',
                      assetData.get('networkconfig') ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _collapsibleCard(
                context,
                title: 'Lifecycle & Status Timeline',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      'Purchase Date',
                      _formatDate(assetData.get('purchasedate')),
                    ),
                    _infoRow(
                      'Installation Date',
                      _formatDate(assetData.get('installationdate')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _collapsibleCard(
                context,
                title: 'Attached Documents',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    documentTile(
                      'Asset Manual',
                      assetData.get('manualUrl') ?? '',
                    ),
                    documentTile(
                      'Warranty Certificate',
                      assetData.get('warrantyUrl') ?? '',
                    ),
                    documentTile('Invoice', assetData.get('invoiceUrl') ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collapsibleCard(
    BuildContext context, {
    required String title,
    required Widget child,
    bool initiallyExpanded = false,
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
              color: Colors.blue,
            ),
          ),
          initiallyExpanded: initiallyExpanded,
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
                fontSize: 15, // slightly larger for better legibility
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
}
