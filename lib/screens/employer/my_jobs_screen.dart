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
      appBar: AppBar(title: const Text('My Jobs')),
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
                    final jobType = job['jobType'] ?? '';
                    final status = job['status'] ?? 'active';
                    final timestamp = job['timestamp'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// TITLE + STATUS
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height: 6),

                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(location),
                            ],

                            const SizedBox(height: 6),

                            /// EXTRA INFO
                            Row(
                              children: [
                                if (wage.isNotEmpty) Text("₹ $wage  •  "),
                                if (jobType.isNotEmpty) Text("$jobType  •  "),
                                Text(timeAgo(timestamp)),
                              ],
                            ),

                            const SizedBox(height: 10),

                            /// 🔥 APPLICANTS COUNT
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('applications')
                                  .where('jobId', isEqualTo: jobId)
                                  .snapshots(),
                              builder: (context, appSnap) {
                                final count =
                                    appSnap.data?.docs.length ?? 0;

                                return Row(
                                  children: [
                                    const Icon(Icons.people, size: 16),
                                    const SizedBox(width: 4),
                                    Text("$count applicants"),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            /// ACTIONS
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ApplicantsScreen(jobId: jobId),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.people),
                                  label: const Text('View Applicants'),
                                ),

                                Row(
                                  children: [

                                    /// 🔥 QUICK STATUS
                                    PopupMenuButton<String>(
                                      onSelected: (value) =>
                                          updateStatus(jobId, value),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: "active",
                                            child: Text("Mark Active")),
                                        PopupMenuItem(
                                            value: "closed",
                                            child: Text("Close Job")),
                                        PopupMenuItem(
                                            value: "filled",
                                            child: Text("Mark Filled")),
                                      ],
                                      child: const Icon(Icons.more_vert),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                EditJobScreen(jobId: jobId),
                                          ),
                                        );
                                      },
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => deleteJob(jobId),
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