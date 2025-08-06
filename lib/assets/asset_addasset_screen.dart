import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'asset_dashboard_screen.dart';

class AddAssetScreen extends StatefulWidget {
  final Map<String, dynamic>? assetData;

  const AddAssetScreen({super.key, this.assetData});

  @override
  _AddAssetScreenState createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text inputs
  late TextEditingController assetIDController;
  late TextEditingController assetNameController;
  late TextEditingController locationController;
  late TextEditingController floorZoneController;
  late TextEditingController roomAreaController;
  late TextEditingController manufacturerController;
  late TextEditingController modelNumberController;
  late TextEditingController serialNumberController;
  late TextEditingController technicalSpecsController;
  late TextEditingController networkConfigController;
  late TextEditingController purchaseDateController;
  late TextEditingController installationDateController;
  late TextEditingController manualUrlController;
  late TextEditingController warrantyUrlController;
  late TextEditingController invoiceUrlController;

  // Dropdown selections
  String? selectedAssetGroup;
  String? selectedCondition;
  String? selectedStatus;

  // Dropdown options
  final List<String> assetGroups = [
    'Electrical',
    'Mechanical',
    'IT',
    'Furniture',
    'Other',
  ];
  final List<String> conditions = [
    'Working',
    'Under Maintenance',
    'Breakdown',
    'Degrading',
  ];
  final List<String> statuses = ['Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    final data = widget.assetData ?? {};

    assetIDController = TextEditingController(text: data['assetID'] ?? '');
    assetNameController = TextEditingController(text: data['assetname'] ?? '');
    locationController = TextEditingController(text: data['location'] ?? '');
    floorZoneController = TextEditingController(text: data['floorzone'] ?? '');
    roomAreaController = TextEditingController(text: data['roomarea'] ?? '');
    manufacturerController = TextEditingController(
      text: data['manufacturer'] ?? '',
    );
    modelNumberController = TextEditingController(
      text: data['modelnumber'] ?? '',
    );
    serialNumberController = TextEditingController(
      text: data['serialnumber'] ?? '',
    );
    technicalSpecsController = TextEditingController(
      text: data['technicalclassification'] ?? '',
    );
    networkConfigController = TextEditingController(
      text: data['networkconfig'] ?? '',
    );
    purchaseDateController = TextEditingController(
      text: _formatDate(data['purchasedate']),
    );
    installationDateController = TextEditingController(
      text: _formatDate(data['installationdate']),
    );
    manualUrlController = TextEditingController(text: data['manualurl'] ?? '');
    warrantyUrlController = TextEditingController(
      text: data['warrantyurl'] ?? '',
    );
    invoiceUrlController = TextEditingController(
      text: data['invoiceurl'] ?? '',
    );

    // Set dropdown selections based on existing data or null
    selectedAssetGroup =
        data['assetgroup'] != null && assetGroups.contains(data['assetgroup'])
            ? data['assetgroup']
            : null;
    selectedCondition =
        data['condition'] != null && conditions.contains(data['condition'])
            ? data['condition']
            : null;
    selectedStatus =
        data['status'] != null && statuses.contains(data['status'])
            ? data['status']
            : null;
  }

  @override
  void dispose() {
    assetIDController.dispose();
    assetNameController.dispose();
    locationController.dispose();
    floorZoneController.dispose();
    roomAreaController.dispose();
    manufacturerController.dispose();
    modelNumberController.dispose();
    serialNumberController.dispose();
    technicalSpecsController.dispose();
    networkConfigController.dispose();
    purchaseDateController.dispose();
    installationDateController.dispose();
    manualUrlController.dispose();
    warrantyUrlController.dispose();
    invoiceUrlController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      final d = date.toDate();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (date is DateTime) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (date is String) return date;
    return '';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initialDate;
    try {
      initialDate =
          controller.text.isNotEmpty
              ? DateTime.parse(controller.text)
              : DateTime.now();
    } catch (e) {
      initialDate = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _infoRow(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    void Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        readOnly: readOnly,
        onTap: onTap,
      ),
    );
  }

  Widget _dropdownRow(
    String label,
    String? selectedValue,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isDense: true,
            isExpanded: true,
            onChanged: onChanged,
            items:
                options
                    .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                    )
                    .toList(),
            hint: Text('Select $label'),
          ),
        ),
      ),
    );
  }

  Widget _urlRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: _infoRow(label, controller, keyboardType: TextInputType.url),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_browser),
          onPressed: () async {
            final url = controller.text.trim();
            if (url.isNotEmpty && await canLaunch(url)) {
              await launch(url);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Cannot open URL: $url')));
            }
          },
        ),
      ],
    );
  }

  Future<void> _submit() async {
    // No mandatory fields, so no validation here.
    final Map<String, dynamic> assetDataToSave = {
      'assetID': assetIDController.text.trim(),
      'assetname': assetNameController.text.trim(),
      'assetgroup': selectedAssetGroup ?? '',
      'condition': selectedCondition ?? '',
      'status': selectedStatus ?? '',
      'location': locationController.text.trim(),
      'floorzone': floorZoneController.text.trim(),
      'roomarea': roomAreaController.text.trim(),
      'manufacturer': manufacturerController.text.trim(),
      'modelnumber': modelNumberController.text.trim(),
      'serialnumber': serialNumberController.text.trim(),
      'technicalclassification': technicalSpecsController.text.trim(),
      'networkconfig': networkConfigController.text.trim(),
      'purchasedate': purchaseDateController.text.trim(),
      'installationdate': installationDateController.text.trim(),
      'manualurl': manualUrlController.text.trim(),
      'warrantyurl': warrantyUrlController.text.trim(),
      'invoiceurl': invoiceUrlController.text.trim(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('AssetRegister')
          .add(assetDataToSave);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Asset saved successfully')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save asset: $e')));
    }
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
            title: const Text(
              "Add New asset",
              style: TextStyle(
                color: Colors.white, // Explicitly set font color to white
                fontWeight: FontWeight.w600, // Optional: make it bold
                fontSize: 20, // Optional: adjust size as needed
              ),
            ),
            backgroundColor:
                Colors.transparent, // Allows gradient to show through
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ), // Icons to white
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssetDashboardScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _infoRow('Asset ID', assetIDController),
              _infoRow('Asset Name', assetNameController),
              _dropdownRow(
                'Asset Group',
                selectedAssetGroup,
                assetGroups,
                (val) => setState(() => selectedAssetGroup = val),
              ),
              _dropdownRow(
                'Condition',
                selectedCondition,
                conditions,
                (val) => setState(() => selectedCondition = val),
              ),
              _dropdownRow(
                'Status',
                selectedStatus,
                statuses,
                (val) => setState(() => selectedStatus = val),
              ),

              const SizedBox(height: 20),
              const Text(
                'Location & Assignment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _infoRow('Location', locationController),
              _infoRow('Floor / Zone', floorZoneController),
              _infoRow('Room / Area', roomAreaController),

              const SizedBox(height: 20),
              const Text(
                'Technical/Manufacturer Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _infoRow('Manufacturer', manufacturerController),
              _infoRow('Model', modelNumberController),
              _infoRow('Serial Number', serialNumberController),
              _infoRow('Technical Specs', technicalSpecsController),
              _infoRow('Network Config', networkConfigController),

              const SizedBox(height: 20),
              const Text(
                'Lifecycle & Status Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _infoRow(
                'Purchase Date',
                purchaseDateController,
                readOnly: true,
                onTap: () => _pickDate(purchaseDateController),
              ),
              _infoRow(
                'Installation Date',
                installationDateController,
                readOnly: true,
                onTap: () => _pickDate(installationDateController),
              ),

              const SizedBox(height: 20),
              const Text(
                'Attached Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _urlRow('Asset Manual', manualUrlController),
              _urlRow('Warranty Certificate', warrantyUrlController),
              _urlRow('Invoice', invoiceUrlController),

              const SizedBox(height: 30),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit'),
                    ),
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
