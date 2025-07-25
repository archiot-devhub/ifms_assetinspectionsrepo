import 'package:flutter/material.dart';

class GeneralSuccessScreen extends StatelessWidget {
  const GeneralSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Network image instead of local asset
              Image.network(
                'https://cdn2.iconfinder.com/data/icons/greenline/512/check-512.png',
                height: 160,
              ),
              const SizedBox(height: 24),
              const Text(
                'Checklist Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your general inspection checklist has been successfully submitted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Inspections'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
