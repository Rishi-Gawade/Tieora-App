import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/employer/applicants/applicants_screen.dart';
import 'package:mobile_app/screens/employer/edit_job_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  bool _loading = false;

  Future<void> deleteJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete job?'),
        content: const Text('This will permanently delete the job. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job deleted')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🔥 UPDATE STATUS
  Future<void> updateStatus(String jobId, String status) async {
    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .update({"status": status});
  }

  /// 🔥 TIME AGO
  String timeAgo(Timestamp? ts) {
    if (ts == null) return "";
    final diff = DateTime.now().difference(ts.toDate());

    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    return "Just now";
  }

  Color statusColor(String status) {
    switch (status) {
      case "closed":
        return Colors.red;
      case "filled":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('jobs')
        .where('postedBy', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "My Jobs",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snap.data!.docs;

                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aTime = (aData['timestamp'] is Timestamp)
                      ? (aData['timestamp'] as Timestamp).millisecondsSinceEpoch
                      : 0;

                  final bTime = (bData['timestamp'] is Timestamp)
                      ? (bData['timestamp'] as Timestamp).millisecondsSinceEpoch
                      : 0;

                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'You have not posted any jobs yet.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final job = doc.data() as Map<String, dynamic>;
                    final jobId = doc.id;

                    final title = job['title'] ?? 'No title';
                    final description = job['description'] ?? '';
                    final location = job['locationText'] ?? '';
                    final wage = job['wage'] ?? '';
                    final status = job['status'] ?? 'active';
                    final timestamp = job['timestamp'];

                   return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                    BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    ),
                    ],
                    border: Border.all(
                    color: Colors.grey.shade200,
                    ),
                    ),
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                        /// HEADER
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                 maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(status).withOpacity(.12),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor(status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// LOCATION
                        if (location.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        /// SALARY
                        if (wage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.currency_rupee,
                                  size: 18,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "₹ ${wage.toString()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        /// TIME
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeAgo(timestamp),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// APPLICANTS
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('applications')
                              .where('jobId', isEqualTo: jobId)
                              .snapshots(),
                          builder: (context, appSnap) {
                            final count = appSnap.data?.docs.length ?? 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people_alt_outlined,
                                    color: Colors.blue.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$count Applicant${count == 1 ? '' : 's'} Applied",
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        /// ACTIONS
                        Row(
                          children: [

                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ApplicantsScreen(jobId: jobId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.people_alt_outlined),
                                label: const Text("Applicants"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditJobScreen(jobId: jobId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text("Edit"),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == "delete") {
                                  deleteJob(jobId);
                                } else {
                                  updateStatus(jobId, value);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: "active",
                                  child: Text("Mark Active"),
                                ),
                                PopupMenuItem(
                                  value: "filled",
                                  child: Text("Mark Filled"),
                                ),
                                PopupMenuItem(
                                  value: "closed",
                                  child: Text("Close Job"),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    ),
                    );

                  },
                );
              },
            ),
    );
  }
}