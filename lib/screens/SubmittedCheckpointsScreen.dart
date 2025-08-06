import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmittedCheckpointsScreen extends StatelessWidget {
  final String inspectionId;

  const SubmittedCheckpointsScreen({super.key, required this.inspectionId});

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
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            title: const Text("Submitted Checkpoints"),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('SubmittedCheckpoints')
                  .where('inspectionID', isEqualTo: inspectionId)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No submitted checkpoints found.'),
              );
            }

            final docs = snapshot.data!.docs;

            // Extract Asset ID and Asset Name from first document, fallback safely
            final firstData = docs.first.data() as Map<String, dynamic>?;

            final assetId =
                firstData?['assetId'] ?? firstData?['assetID'] ?? '-';
            final assetName =
                firstData?['assetName'] ?? firstData?['assetname'] ?? '-';

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                // Asset info section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F0FF), // Light blue background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB3D4FC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Asset ID:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF004EFF), // Blue to match header
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assetId,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(
                            0xFF002F99,
                          ), // Alternate blue for content
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Asset Name:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF004EFF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assetName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF002F99),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkpoints list
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final checkpointTitle =
                      data['checkpoint'] ?? 'Unnamed Checkpoint';
                  final response = data['response'] ?? '-';
                  final remarks = data['remarks'] ?? '-';
                  final imageUrl = (data['imageUrl'] as String?) ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checkpointTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Response: $response",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Remarks: $remarks",
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              progress.expectedTotalBytes !=
                                                      null
                                                  ? progress
                                                          .cumulativeBytesLoaded /
                                                      progress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (_, __, ___) => SizedBox(
                                        height: 180,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 60,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
