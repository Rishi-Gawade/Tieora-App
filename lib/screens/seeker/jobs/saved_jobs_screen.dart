// lib/screens/saved_jobs_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'job_detail_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view saved jobs'),
        ),
      );
    }

    final uid = user.uid;
    final fire = FirebaseFirestore.instance;

    final savedRef = fire
        .collection('users')
        .doc(uid)
        .collection('saved_jobs')
        .orderBy('savedAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Jobs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: savedRef.snapshots(),

        builder: (context, snap) {

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final savedDocs = snap.data?.docs ?? [];

          if (savedDocs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedDocs.length,

            itemBuilder: (context, index) {

              final jobId = savedDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: fire.collection('jobs').doc(jobId).get(),

                builder: (context, jobSnap) {

                  if (!jobSnap.hasData || !jobSnap.data!.exists) {
                    return const SizedBox();
                  }

                  final job =
                      jobSnap.data!.data() as Map<String, dynamic>?;

                  if (job == null) {
                    return const SizedBox();
                  }

                  final String title =
                      job['title'] ?? 'No title';

                  final String description =
                      job['description'] ?? '';

                  final String salary =
                      job['salary']?.toString() ?? 'Not specified';

                  final String location =
                      job['locationText'] ?? 'Location shared';

                  return _modernJobCard(
                    context,
                    uid,
                    fire,
                    jobId,
                    title,
                    description,
                    salary,
                    location,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 🔥 Modern Job Card

  Widget _modernJobCard(
    BuildContext context,
    String uid,
    FirebaseFirestore fire,
    String jobId,
    String title,
    String description,
    String salary,
    String location,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  JobDetailScreen(jobId: jobId),
            ),
          );
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Title + Remove Icon
            Row(
              children: [

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.bookmark_remove,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {

                    await fire
                        .collection('users')
                        .doc(uid)
                        .collection('saved_jobs')
                        .doc(jobId)
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from saved jobs'),
                      ),
                    );
                  },
                ),
              ],
            ),

            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            /// Salary + Location Row
            Row(
              children: [

                const Icon(Icons.currency_rupee,
                    size: 16, color: Colors.green),

                const SizedBox(width: 4),

                Text(
                  salary,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 14),

                const Icon(Icons.location_on,
                    size: 16, color: Colors.grey),

                const SizedBox(width: 4),

                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 Empty State UI

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [

          Icon(
            Icons.bookmark_border,
            size: 70,
            color: Colors.grey,
          ),

          SizedBox(height: 12),

          Text(
            "No saved jobs yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 6),

          Text(
            "Jobs you save will appear here",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}