import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Asset QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (!_isScanning) return; // Prevent multiple pops
          _isScanning = false;

          final barcode =
              capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
          final code = barcode?.rawValue;
          if (code != null && code.trim().isNotEmpty) {
            print("✅ QR Code Scanned: $code");
            Navigator.pop(context, code);
          } else {
            _isScanning = true; // Re-enable scanning if invalid code
          }
        },
      ),
    );
  }
}
