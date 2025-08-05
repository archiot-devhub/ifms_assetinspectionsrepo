import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'asset_detail_screen.dart';
// Make sure the import path is correct and AssetDetailScreen is defined in this file.
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:open_file/open_file.dart';
import 'bulk_upload_asset_screen.dart';
import 'asset_dashboard_screen.dart';
import 'dart:io';
import 'asset_details_qr_scanner_screen.dart';
import 'asset_timeline_screen.dart';
import 'asset_addasset_screen.dart';

class AssetRegisterScreen extends StatefulWidget {
  const AssetRegisterScreen({super.key});

  @override
  State<AssetRegisterScreen> createState() => _AssetRegisterScreenState();
}

class _AssetRegisterScreenState extends State<AssetRegisterScreen> {
  String searchText = '';
  String selectedCondition = 'All';
  String selectedStatus = 'All'; // Keep for Add/Edit forms only
  String selectedCategory = 'All'; // New Category filter

  final List<String> conditionOptions = [
    'All',
    'Working',
    'Breakdown',
    'Under Maintenance',
    'Degrading',
  ];
  final List<String> statusOptions = ['All', 'Active', 'Inactive'];

  final List<String> categoryOptions = ['All', 'HVAC', 'Pumps', 'Firesystem'];

  Future<void> _exportToCSV(List<QueryDocumentSnapshot> docs) async {
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
        'Location',
      ]);
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
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
              ? DateFormat(
                'yyyy-MM-dd',
              ).format((data['purchasedate'] as Timestamp).toDate())
              : data['purchasedate']?.toString() ?? '',
          data['replacementcost'] ?? '',
          data['depreciationrate'] ?? '',
          data['depreciationvalue'] ?? '',
          data['residualvalue'] ?? '',
          data['elapsedlife'] ?? '',
          data['usefullife'] ?? '',
          data['installationdate'] is Timestamp
              ? DateFormat(
                'yyyy-MM-dd',
              ).format((data['installationdate'] as Timestamp).toDate())
              : data['installationdate']?.toString() ?? '',
          data['locationID'] ?? '',
        ]);
      }
      String csvData = const ListToCsvConverter().convert(rows);
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final filePath =
          '${dir!.path}/asset_register_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File(filePath);
      await file.writeAsString(csvData);
      await OpenFile.open(filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV downloaded and opened')),
      );
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
                          _sectionHeader('Key Details'),
                          _buildTextField('Asset ID', assetData),
                          _buildTextField('Asset Name', assetData),
                          _buildTextField('Asset Group', assetData),
                          _buildTextField(
                            'status',
                            assetData,
                          ), // status stays here
                          _buildTextField('condition', assetData),

                          const SizedBox(height: 12),
                          _sectionHeader('Technical Details'),
                          _buildTextField('technicalclassification', assetData),
                          _buildTextField('serialnumber', assetData),
                          _buildTextField('modelnumber', assetData),
                          _buildTextField('manufacturer', assetData),

                          const SizedBox(height: 12),
                          _sectionHeader('Financial Details'),
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
                          _sectionHeader('Lifecycle Details'),
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
                      setState(() {}); // Refresh after adding
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
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
      child: Builder(
        builder: (context) {
          return TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                controller.text = DateFormat('yyyy-MM-dd').format(picked);
                assetData[label] = Timestamp.fromDate(picked);
              }
            },
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                DateTime? date = DateTime.tryParse(value);
                if (date != null) {
                  assetData[label] = Timestamp.fromDate(date);
                }
              }
            },
          );
        },
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
                          .update({
                            'condition': condition,
                            'status': status,
                            'modifiedTime': FieldValue.serverTimestamp(),
                          });
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

  Color _conditionDotColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'working':
        return Colors.green;
      case 'breakdown':
        return Colors.red;
      case 'degrading':
        return Colors.purple;
      case 'under maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _conditionPillColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'working':
        return Colors.green.shade50;
      case 'breakdown':
        return Colors.red.shade50;
      case 'under maintenance':
        return Colors.orange.shade50;
      case 'degrading':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _conditionPillTextColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'working':
        return Colors.green.shade700;
      case 'breakdown':
        return Colors.red.shade700;
      case 'under maintenance':
        return Colors.orange.shade700;
      case 'degrading':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: () async {
              final snapshot =
                  await FirebaseFirestore.instance
                      .collection('AssetRegister')
                      .get();
              await _exportToCSV(snapshot.docs);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Asset',
            onPressed: _showAddAssetPopup,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by Asset Name or ID',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: InkWell(
                        onTap: () {
                          // Navigate to the asset_details_qr_scanner_screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AssetScanScreen(),
                            ),
                          );
                        },
                        child: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ),
                    onChanged:
                        (value) =>
                            setState(() => searchText = value.toLowerCase()),
                  ),
                  const SizedBox(height: 8),
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
                          value: selectedCategory,
                          items:
                              categoryOptions
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => selectedCategory = value!),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
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
                        final data = doc.data() as Map<String, dynamic>;
                        final assetName =
                            (data['assetname'] ?? '').toString().toLowerCase();
                        final assetID =
                            (data['assetID'] ?? '').toString().toLowerCase();
                        final condition = (data['condition'] ?? '').toString();
                        final technicalClassification =
                            (data['technicalclassification'] ?? '').toString();

                        final matchesSearch =
                            assetName.contains(searchText) ||
                            assetID.contains(searchText);
                        final matchesCondition =
                            selectedCondition == 'All' ||
                            condition == selectedCondition;
                        final matchesCategory =
                            selectedCategory == 'All' ||
                            technicalClassification == selectedCategory;

                        return matchesSearch &&
                            matchesCondition &&
                            matchesCategory;
                      }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No assets found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final doc = docs[idx];
                      final data = doc.data() as Map<String, dynamic>;
                      final condition = data['condition'] ?? '';
                      final status = data['status'] ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0.7,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AssetDetailScreen(assetData: doc),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status dot
                                Container(
                                  width: 13,
                                  height: 13,
                                  margin: const EdgeInsets.only(
                                    right: 10,
                                    top: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        status.toString().toLowerCase() ==
                                                'active'
                                            ? Colors.green
                                            : status.toString().toLowerCase() ==
                                                'inactive'
                                            ? Colors.red
                                            : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Text info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Asset Name + ID in blue
                                      Text(
                                        '${data['assetname'] ?? "--"} (${data['assetID'] ?? "--"})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(
                                            0xFF004EFF,
                                          ), // Blue color as per image
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Asset Group
                                      // Line 2: Asset Group
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Group: ',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '${data['assetgroup'] ?? "--"}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Location: ',
                                              style: const TextStyle(
                                                fontSize:
                                                    11, // !! <-- match Group
                                                fontWeight: FontWeight.normal,
                                                color:
                                                    Colors
                                                        .black87, // !! <-- match Group (was probably black54)
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '${data['locationID'] ?? "--"}',
                                              style: const TextStyle(
                                                fontSize:
                                                    11, // !! <-- match Group
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Colors
                                                        .black87, // !! <-- match Group
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Technical: ',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '${data['technicalclassification'] ?? "--"}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Pill for condition + edit button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Condition pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _conditionPillColor(
                                          condition.toString(),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (condition.toString().toLowerCase() ==
                                                'working')
                                            ? 'Working'
                                            : (condition
                                                    .toString()
                                                    .toLowerCase() ==
                                                'breakdown')
                                            ? 'Breakdown'
                                            : (condition
                                                    .toString()
                                                    .toLowerCase() ==
                                                'under maintenance')
                                            ? 'Under Maintenance'
                                            : (condition
                                                    .toString()
                                                    .toLowerCase() ==
                                                'degrading')
                                            ? 'Degrading'
                                            : condition.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _conditionPillTextColor(
                                            condition.toString(),
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    // Edit icon
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      splashRadius: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showEditPopup(doc),
                                      tooltip: 'Edit',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // 'All Assets' tab is index 1
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'All Assets',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Asset'),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline), // Timeline tab
            label: 'Asset Timeline',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AssetDashboardScreen()),
            );
          } else if (index == 1) {
            // Already on current screen - do nothing
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AddAssetScreen()),
            );
          } else if (index == 3) {
            // Navigate to Asset Timeline screen (import and use your timeline screen here)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AllAssetsTimelineScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}
