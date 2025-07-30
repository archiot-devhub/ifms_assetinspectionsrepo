import 'package:flutter/material.dart';
import 'inspection_list_screen.dart'; // Assuming your inspection list screen is named this way and in the same folder or adjust the import path accordingly

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confirmation Icon/Image
              Image.network(
                'https://cdn-icons-png.flaticon.com/512/190/190411.png', // A cleaner checkmark icon; you can keep your own URL
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const Text(
                'Checklist Submitted!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your inspection checklist has been successfully submitted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    // Navigate to InspectionListScreen and clear stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InspectionListScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Inspection List'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
