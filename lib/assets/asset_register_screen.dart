import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'asset_detail_screen.dart'; // ⬅️ You'll create this next

class AssetRegisterScreen extends StatefulWidget {
  const AssetRegisterScreen({super.key});

  @override
  State<AssetRegisterScreen> createState() => _AssetRegisterScreenState();
}

class _AssetRegisterScreenState extends State<AssetRegisterScreen> {
  String searchText = '';
  String selectedCondition = 'All';
  String selectedStatus = 'All';

  final List<String> conditionOptions = [
    'All',
    'Working',
    'Breakdown',
    'Under Maintenance',
    'Degrading',
  ];

  final List<String> statusOptions = ['All', 'Active', 'Inactive'];

  Future<void> _refreshAssets() async {
    setState(() {}); // Just triggers a rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asset Register')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by Asset Name or ID',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCondition,
                        items:
                            conditionOptions.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                        onChanged:
                            (value) =>
                                setState(() => selectedCondition = value!),
                        decoration: const InputDecoration(
                          labelText: 'Condition',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items:
                            statusOptions.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                        onChanged:
                            (value) => setState(() => selectedStatus = value!),
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAssets,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('AssetRegister')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs =
                      snapshot.data!.docs.where((doc) {
                        final assetName =
                            doc['assetname'].toString().toLowerCase();
                        final assetID = doc['assetID'].toString().toLowerCase();
                        final condition = doc['condition'];
                        final status = doc['status'];

                        final matchesSearch =
                            assetName.contains(searchText) ||
                            assetID.contains(searchText);
                        final matchesCondition =
                            selectedCondition == 'All' ||
                            condition == selectedCondition;
                        final matchesStatus =
                            selectedStatus == 'All' || status == selectedStatus;

                        return matchesSearch &&
                            matchesCondition &&
                            matchesStatus;
                      }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No assets found.'));
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final asset = docs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(asset['assetname']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${asset['assetID']}'),
                              Text(
                                'Status: ${asset['status']} | Condition: ${asset['condition']}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          AssetDetailScreen(assetData: asset),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
