import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'asset_detail_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:open_file/open_file.dart';
import 'bulk_upload_asset_screen.dart';
import 'dart:io';

class AssetRegisterScreen extends StatefulWidget {
  const AssetRegisterScreen({super.key});

  @override
  State<AssetRegisterScreen> createState() => _AssetRegisterScreenState();
}

class _AssetRegisterScreenState extends State<AssetRegisterScreen> {
  List<Map<String, dynamic>> _assets = [];

  @override
  void initState() {
    super.initState();
    fetchAssets(); // 🔹 Call the function to load Firestore data
  }

  Future<void> fetchAssets() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('AssetRegister').get();
    setState(() {
      _assets = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

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

  Future<void> _exportToCSV(List<Map<String, dynamic>> assetList) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add([
        'Asset ID',
        'Asset Name',
        'Asset Group',
        'Condition',
        'Status',
        'Technical Classification',
        'Serial Number',
        'Model Number',
        'Manufacturer',
        'Purchase Cost',
        'Vendor Name',
        'Purchase Date',
        'Replacement Cost',
        'Depreciation Rate',
        'Depreciation Value',
        'Residual Value',
        'Elapsed Life',
        'Useful Life',
        'Installation Date',
      ]);

      for (var data in assetList) {
        rows.add([
          data['assetID'] ?? '',
          data['assetname'] ?? '',
          data['assetgroup'] ?? '',
          data['condition'] ?? '',
          data['status'] ?? '',
          data['technicalclassification'] ?? '',
          data['serialnumber'] ?? '',
          data['modelnumber'] ?? '',
          data['manufacturer'] ?? '',
          data['purchasecost'] ?? '',
          data['vendorname'] ?? '',
          data['purchasedate'] is Timestamp
              ? data['purchasedate']?.toDate().toString() ?? ''
              : data['purchasedate']?.toString() ?? '',
          data['replacementcost'] ?? '',
          data['depreciationrate'] ?? '',
          data['depreciationvalue'] ?? '',
          data['residualvalue'] ?? '',
          data['elapsedlife'] ?? '',
          data['usefullife'] ?? '',
          data['installationdate'] is Timestamp
              ? data['installationdate']?.toDate().toString() ?? ''
              : data['installationdate']?.toString() ?? '',
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      // Get download directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = await getExternalStorageDirectory(); // App directory
      } else {
        downloadsDir = await getApplicationDocumentsDirectory(); // iOS safe
      }

      final now = DateTime.now();
      final fileName =
          'asset_register_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
      final filePath = '${downloadsDir!.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvData);

      // Open the file
      await OpenFile.open(filePath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV downloaded and opened')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    }
  }

  void _showAddAssetPopup() {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> assetData = {};

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Asset',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Key Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildTextField('assetID', assetData),
                          _buildTextField('assetname', assetData),
                          _buildTextField('assetgroup', assetData),
                          _buildTextField('status', assetData),
                          _buildTextField('condition', assetData),

                          const SizedBox(height: 12),
                          const Text(
                            'Technical Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildTextField('technicalclassification', assetData),
                          _buildTextField('serialnumber', assetData),
                          _buildTextField('modelnumber', assetData),
                          _buildTextField('manufacturer', assetData),

                          const SizedBox(height: 12),
                          const Text(
                            'Financial Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildTextField(
                            'purchasecost',
                            assetData,
                            isNumber: true,
                          ),
                          _buildTextField('vendorname', assetData),
                          _buildDateField('purchasedate', assetData),
                          _buildTextField(
                            'replacementcost',
                            assetData,
                            isNumber: true,
                          ),
                          _buildTextField(
                            'depreciationrate',
                            assetData,
                            isNumber: true,
                          ),
                          _buildTextField(
                            'depreciationvalue',
                            assetData,
                            isNumber: true,
                          ),
                          _buildTextField(
                            'residualvalue',
                            assetData,
                            isNumber: true,
                          ),

                          const SizedBox(height: 12),
                          const Text(
                            'Lifecycle Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildTextField(
                            'elapsedlife',
                            assetData,
                            isNumber: true,
                          ),
                          _buildTextField(
                            'usefullife',
                            assetData,
                            isNumber: true,
                          ),
                          _buildDateField('installationdate', assetData),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    Map<String, dynamic> assetData, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onSaved:
            (value) =>
                assetData[label] =
                    isNumber ? num.tryParse(value ?? '') ?? 0 : value ?? '',
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDateField(String label, Map<String, dynamic> assetData) {
    TextEditingController controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(labelText: label),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
            assetData[label] = pickedDate;
          }
        },
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Asset',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Asset ID: ${asset['assetID']}'),
                Text('Asset Name: ${asset['assetname']}'),
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
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('AssetRegister')
                          .doc(asset.id)
                          .update({'condition': condition, 'status': status});
                      Navigator.pop(context);
                    },
                    child: const Text('Update'),
                  ),
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
            icon: const Icon(Icons.file_upload),
            tooltip: 'Bulk Upload',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BulkUploadAssetScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: () async {
              final snapshot =
                  await FirebaseFirestore.instance
                      .collection('AssetRegister')
                      .get();
              await _exportToCSV(
                snapshot.docs.map((doc) => doc.data()).toList(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Asset',
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
