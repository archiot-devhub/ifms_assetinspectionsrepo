import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'asset_detail_screen.dart';

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
    setState(() {});
  }

  void _showAddAssetPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // optional: prevent accidental close
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final Map<String, dynamic> assetData = {};

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Text(
                            'Add New Asset',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Form(
                              key: formKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildTextField('assetID', assetData),
                                    _buildTextField('assetname', assetData),
                                    _buildTextField('assetgroup', assetData),
                                    _buildTextField('condition', assetData),
                                    _buildTextField('criticality', assetData),
                                    _buildTextField('locationID', assetData),
                                    _buildTextField('project', assetData),
                                    _buildTextField('manufacturer', assetData),
                                    _buildTextField('modelnumber', assetData),
                                    _buildTextField('serialnumber', assetData),
                                    _buildTextField(
                                      'powerspecification',
                                      assetData,
                                    ),
                                    _buildTextField('status', assetData),
                                    _buildTextField(
                                      'technicalclassification',
                                      assetData,
                                    ),
                                    _buildTextField('imageUrl', assetData),
                                    _buildTextField('manualUrl', assetData),
                                    _buildTextField('invoiceUrl', assetData),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                await FirebaseFirestore.instance
                                    .collection('AssetRegister')
                                    .add(assetData);
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Add Asset'),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, Map<String, dynamic> dataMap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onSaved: (value) => dataMap[label] = value ?? '',
      ),
    );
  }

  void _showEditPopup(DocumentSnapshot asset) {
    String condition = asset['condition'];
    String status = asset['status'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Asset',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: condition,
                  items:
                      conditionOptions
                          .where((e) => e != 'All')
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (val) => condition = val!,
                  decoration: const InputDecoration(labelText: 'Condition'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  items:
                      statusOptions
                          .where((e) => e != 'All')
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) => status = val!,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('AssetRegister')
                        .doc(asset.id)
                        .update({'condition': condition, 'status': status});
                    Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Register'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAssetPopup,
          ),
        ],
      ),
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
                            conditionOptions
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
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
                            statusOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AssetDetailScreen(
                                            assetData: asset,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditPopup(asset),
                              ),
                            ],
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
