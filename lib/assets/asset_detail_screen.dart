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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child:
                  isWide
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topQuickActions(context, assetData),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImage(assetImageUrl),
                              const SizedBox(width: 36),
                              Expanded(child: _buildDetailsSection(context)),
                            ],
                          ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topQuickActions(context, assetData),
                          const SizedBox(height: 12),
                          Center(child: _buildImage(assetImageUrl)),
                          const SizedBox(height: 18),
                          _buildDetailsSection(context),
                        ],
                      ),
            );
          },
        ),
      ),
    );
  }

  /// Top "Maintenance" and "Next Due" icon buttons row
  // Update _topQuickActions to accept assetData
  Widget _topQuickActions(
    BuildContext context,
    QueryDocumentSnapshot assetData,
  ) {
    final String assetID = assetData.get('assetID') ?? '';
    final String assetName = assetData.get('assetname') ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _iconAction(
          context,
          icon: Icons.settings,
          label: "Maintenance",
          onTap: () {
            if (assetID.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MaintenanceDetailsPPMScreen(
                        assetID: assetID,
                        assetName: assetName,
                      ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Asset ID not found')),
              );
            }
          },
        ),
        const SizedBox(width: 16),
        _iconAction(
          context,
          icon: Icons.calendar_today_outlined,
          label: "Next Due",
          onTap: () {
            // your existing or new logic for Next Due
          },
        ),
      ],
    );
  }

  Widget _iconAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Key Details'),
        infoRow('Asset ID', assetData.get('assetID') ?? ''),
        infoRow('Asset Name', assetData.get('assetname') ?? ''),
        infoRow('Asset Group', assetData.get('assetgroup') ?? ''),
        infoRow('Status', assetData.get('status') ?? ''),
        infoRow('Condition', assetData.get('condition') ?? ''),

        const SizedBox(height: 16),
        _sectionTitle('Technical Details'),
        infoRow(
          'Technical Classification',
          assetData.get('technicalclassification') ?? '',
        ),
        infoRow('Serial Number', assetData.get('serialnumber') ?? ''),
        infoRow('Model Number', assetData.get('modelnumber') ?? ''),
        infoRow('Manufacturer', assetData.get('manufacturer') ?? ''),

        const SizedBox(height: 16),
        _sectionTitle('Financial Details'),
        infoRow(
          'Purchase Cost',
          assetData.get('purchasecost')?.toString() ?? '',
        ),
        infoRow('Vendor Name', assetData.get('vendorname') ?? ''),
        infoRow('Purchase Date', _formatDate(assetData.get('purchasedate'))),
        infoRow(
          'Replacement Cost',
          assetData.get('replacementcost')?.toString() ?? '',
        ),
        infoRow(
          'Depreciation Rate',
          assetData.get('depreciationrate')?.toString() ?? '',
        ),
        infoRow(
          'Depreciation Value',
          assetData.get('depreciationvalue')?.toString() ?? '',
        ),
        infoRow(
          'Residual Value',
          assetData.get('residualvalue')?.toString() ?? '',
        ),

        const SizedBox(height: 16),
        _sectionTitle('Lifecycle Details'),
        infoRow('Useful Life', assetData.get('usefullife')?.toString() ?? ''),
        infoRow(
          'Installation Date',
          _formatDate(assetData.get('installationdate')),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 10),
        _sectionTitle('Attached Documents'),

        documentTile('Asset Manual', assetData.get('manualUrl') ?? ''),
        documentTile(
          'Warranty Certificate',
          assetData.get('warrantyUrl') ?? '',
        ),
        documentTile('Invoice', assetData.get('invoiceUrl') ?? ''),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      child:
          imageUrl.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: 180,
                  height: 180,
                  errorBuilder:
                      (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 60),
                      ),
                ),
              )
              : const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              (value.trim().isNotEmpty) ? value : '-',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
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
        leading: const Icon(Icons.description),
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

  // Format Firestore Timestamp or other date string
  String _formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is Timestamp) {
      final dt = date.toDate();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    }
    if (date is DateTime) {
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
    return date.toString();
  }
}
