import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AssetDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot assetData;

  const AssetDetailScreen({super.key, required this.assetData});

  @override
  Widget build(BuildContext context) {
    final assetImageUrl = assetData.get('imageUrl') ?? '';
    final assetName = assetData.get('assetname') ?? 'Asset Details';

    return Scaffold(
      appBar: AppBar(title: Text(assetName)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                isWide
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailsSection(context)),
                        const SizedBox(width: 24),
                        _buildImage(assetImageUrl),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImage(assetImageUrl),
                        const SizedBox(height: 16),
                        _buildDetailsSection(context),
                      ],
                    ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asset Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          runSpacing: 12,
          children: [
            infoRow('Asset ID', assetData.get('assetID') ?? ''),
            infoRow('Asset Name', assetData.get('assetname') ?? ''),
            infoRow('Asset Group', assetData.get('assetgroup') ?? ''),
            infoRow('Project', assetData.get('project') ?? ''),
            infoRow('Location ID', assetData.get('locationID') ?? ''),
            infoRow('Condition', assetData.get('condition') ?? ''),
            infoRow('Status', assetData.get('status') ?? ''),
            infoRow('Criticality', assetData.get('criticality') ?? ''),
            infoRow('Manufacturer', assetData.get('manufacturer') ?? ''),
            infoRow('Model Number', assetData.get('modelnumber') ?? ''),
            infoRow('Serial Number', assetData.get('serialnumber') ?? ''),
            infoRow(
              'Power Specification',
              assetData.get('powerspecification') ?? '',
            ),
            infoRow(
              'Technical Classification',
              assetData.get('technicalclassification') ?? '',
            ),
            infoRow('Description', assetData.get('description') ?? ''),
          ],
        ),
        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Attached Documents',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
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
      width: 200,
      height: 200,
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
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
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

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isNotEmpty ? value : '-',
              style: const TextStyle(fontSize: 15),
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
        title: Text(title),
        trailing:
            url.trim().isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.open_in_new),
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
                  style: TextStyle(color: Colors.grey),
                ),
      ),
    );
  }
}
