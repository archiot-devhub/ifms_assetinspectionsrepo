import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'asset_detail_screen.dart';

class AssetScanScreen extends StatefulWidget {
  const AssetScanScreen({super.key});

  @override
  State<AssetScanScreen> createState() => _AssetScanScreenState();
}

class _AssetScanScreenState extends State<AssetScanScreen> {
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return; // prevent multiple scans

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue ?? '';

    // You might want to validate the scanned code format here
    if (code.isNotEmpty) {
      setState(() {
        _isScanning = false;
      });

      // Fetch asset data from Firestore by asset ID scanned
      final query =
          await FirebaseFirestore.instance
              .collection('AssetRegister')
              .where('assetID', isEqualTo: code)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final assetData = query.docs.first;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(assetData: assetData),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Asset not found')));
        setState(() {
          _isScanning = true; // allow scanning again
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Asset QR')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
