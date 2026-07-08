// UPDATED: Rating FIXED + Production Safe

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/app_loader.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_snackbar.dart';

import 'jobs/job_detail_screen.dart';
import '../common/rating_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState
    extends State<MyApplicationsScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fire =
      FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {

    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view your applications'),
        ),
      );
    }

    final applicationsQuery = _fire
        .collection('applications')
        .where('seekerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Applications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: applicationsQuery.snapshots(),

        builder: (context, snap) {

          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }

          if (snap.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppSnackbar.showError(context, "Failed to load applications");
            });

            return Center(
              child: ElevatedButton(
                onPressed: () {
                  (context as Element).markNeedsBuild();
                },
                child: const Text("Retry"),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.work_outline,
              title: "No applications yet",
              subtitle: "Jobs you apply to will appear here",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,

            itemBuilder: (context, i) {

              final doc = docs[i];
              final app = doc.data() as Map<String, dynamic>;

              final jobId = (app['jobId'] ?? '').toString();
              final employerId = (app['employerId'] ?? '').toString();

              final rawStatus = (app['status'] ?? 'pending').toString();

              String status;
              if (rawStatus == 'pending') {
                status = 'applied';
              } else if (rawStatus == 'accepted') {
                status = 'Hired';
              } else {
                status = rawStatus;
              }

              final isCompleted = app['isCompleted'] ?? false;
              final seekerRated = app['seekerRated'] ?? false;

              final Timestamp? appliedTs =
                  app['createdAt'] is Timestamp
                      ? app['createdAt']
                      : null;

              final appliedAt = appliedTs != null
                  ? _timeAgo(appliedTs.toDate())
                  : 'Unknown';

              return _modernApplicationCard(
                context,
                jobId,
                employerId, // ✅ FIXED
                status,
                appliedAt,
                isCompleted,
                seekerRated,
                doc.id, // 🔥 needed to update rating flag
              );
            },
          );
        },
      ),
    );
  }

  Widget _modernApplicationCard(
    BuildContext context,
    String jobId,
    String employerId,
    String status,
    String appliedAt,
    bool isCompleted,
    bool seekerRated,
    String applicationId,
  ) {

    return FutureBuilder<DocumentSnapshot>(
      future: _fire.collection('jobs').doc(jobId).get(),
      builder: (context, jobSnap) {

        String title = '(Job removed)';
        String employer = 'Employer';
        String phone = '';

        if (jobSnap.hasData && jobSnap.data!.exists) {
          final j = jobSnap.data!.data() as Map<String, dynamic>;
          title = j['title'] ?? title;
          employer = j['postedByName'] ?? employer;
          phone = j['contactPhone'] ?? '';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                employer,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("Applied $appliedAt",
                      style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  TextButton(
                    onPressed: jobId.isEmpty ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(jobId: jobId),
                        ),
                      );
                    },
                    child: const Text("View Job"),
                  ),
                ],
              ),

              if (status == 'Hired')
                _acceptedActions(jobId),

              /// ⭐ FIXED RATING BUTTON
              if (isCompleted && !seekerRated && employerId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RatingScreen(
                              jobId: jobId,
                              toUserId: employerId,
                            ),
                          ),
                        );

                        /// 🔥 UPDATE FLAG AFTER RETURN
                        await FirebaseFirestore.instance
                            .collection('applications')
                            .doc(applicationId)
                            .update({'seekerRated': true});
                      },
                      child: const Text("Rate Employer"),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _acceptedActions(String jobId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _fire.collection('jobs').doc(jobId).get(),
      builder: (context, snap) {

        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox();
        }

        final job = snap.data!.data() as Map<String, dynamic>;
        final phone = (job['contactPhone'] ?? '').toString();

        if (phone.isEmpty) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _callPhone(phone),
              icon: const Icon(Icons.call, size: 18),
              label: const Text("Call Employer"),
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    late Color color;
    late String label;

    switch (status) {
      case 'Hired':
        color = Colors.green;
        label = 'Hired';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'viewed':
        color = Colors.blue;
        label = 'Viewed';
        break;
      default:
        color = Colors.orange;
        label = 'Applied';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}