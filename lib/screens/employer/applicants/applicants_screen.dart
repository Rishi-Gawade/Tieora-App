import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'applicant_detail_screen.dart';

class ApplicantsScreen extends StatelessWidget {
  final String jobId;

  const ApplicantsScreen({super.key, required this.jobId});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "hired":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// 🔥 UPDATE STATUS FUNCTION
  Future<void> _updateStatus(String appId, String status) async {
    try {
      final appRef =
          FirebaseFirestore.instance.collection("applications").doc(appId);

      final appDoc = await appRef.get();

      if (!appDoc.exists) return;

      final jobId = appDoc["jobId"];

      /// UPDATE APPLICATION
      await appRef.update({"status": status});

      /// 🔥 IF HIRED → UPDATE JOB
      if (status == "hired") {
        await FirebaseFirestore.instance
            .collection("jobs")
            .doc(jobId)
            .update({"status": "filled"});
      }

    } catch (e) {
      debugPrint("Status update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    if (jobId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Invalid Job")),
      );
    }

    final query = FirebaseFirestore.instance
        .collection("applications")
        .where("jobId", isEqualTo: jobId)
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Applicants"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            debugPrint("Applicants Error: ${snapshot.error}");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();

            if (error.contains("FAILED_PRECONDITION")) {
              return const Center(
                child: Text(
                  "Index required. Please check Firestore indexes.",
                ),
              );
            }

            return const Center(child: Text("Something went wrong"));
          }

          final applicants = snapshot.data?.docs ?? [];

          if (applicants.isEmpty) {
            return const Center(
              child: Text(
                "No applicants yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: applicants.length,
            itemBuilder: (context, i) {

              final doc = applicants[i];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final name = (data["name"] ?? "Unknown").toString();
              final status = (data["status"] ?? "pending").toString();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [

                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),

                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      subtitle: Row(
                        children: [
                          const Text("Status: "),
                          Text(
                            status,
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      trailing:
                          const Icon(Icons.arrow_forward_ios, size: 16),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplicantDetailScreen(
                              applicantId: doc.id,
                              jobId: data['jobId'] ?? '',           // 🔥 REQUIRED
                              seekerId: data['seekerId'] ?? '',     // 🔥 REQUIRED
                              name: data['name'] ?? 'User',         // 🔥 REQUIRED
                              jobTitle: data['jobTitle'] ?? '', 
                            ),
                          ),
                        );
                      },
                    ),

                    /// 🔥 ACTION BUTTONS
                    if (status == "pending")
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 10, left: 12, right: 12),
                        child: Row(
                          children: [

                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _updateStatus(doc.id, "hired"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("Hire"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _updateStatus(doc.id, "rejected"),
                                child: const Text("Reject"),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}