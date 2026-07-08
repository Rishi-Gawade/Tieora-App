import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/job_model.dart';
import '../../../models/application_model.dart';
import '../../../services/application_service.dart';
import '../../../services/chat_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/notification_write_service.dart';
import '../../common/message_detail_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({required this.jobId, super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final ApplicationService _applicationService;
  late final ChatService _chatService;

  final NotificationWriteService _notificationService =
    NotificationWriteService();

  bool _applying = false;
  bool _alreadyApplied = false;

  @override
  void initState() {
    super.initState();
    _applicationService = ApplicationService();
    _chatService = ChatService();
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _fire
        .collection('applications')
        .where('jobId', isEqualTo: widget.jobId)
        .where('seekerId', isEqualTo: uid)
        .limit(1)
        .get();

    if (!mounted) return;

    setState(() {
      _alreadyApplied = snap.docs.isNotEmpty;
    });
  }

  Future<void> _openChat(JobModel job) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final seekerId = user.uid;
      final employerId = job.postedBy;

      final seekerDoc =
          await _fire.collection('users').doc(seekerId).get();

      final seekerData =
          seekerDoc.data() as Map<String, dynamic>? ?? {};

      final String seekerName =
          (seekerData['fullName'] ?? 'User').toString();

      final threadId = await _chatService.createOrGetThread(
  seekerId: user.uid,
  employerId: job.postedBy,
  seekerName: seekerName,
  employerName: job.postedByName,
  jobId: job.id,
  jobTitle: job.title,
  companyName: job.postedByName,
jobLocation: job.locationText ?? "",
jobScope: job.jobScope ?? "local",
);
      await FirebaseFirestore.instance
    .collection('threads')
    .doc(threadId)
    .update({

      "jobTitle": job.title,

      "companyName": job.postedByName,

      "jobLocation": job.locationText,

      "jobScope": job.jobScope,

      "employerId": job.postedBy,

      "employerName": job.postedByName,

      "seekerId": seekerId,

      "seekerName": seekerName,
    });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessageDetailScreen(
            threadId: threadId,
            jobTitle: job.title,
            otherUserId: employerId,
          ),
        ),
      );
    } catch (e) {
      AppSnackbar.showError(context, "Failed to open chat");
    }
  }

Future<void> _applyToJob(JobModel job) async {
  try {
    final user = _auth.currentUser;
    if (user == null) return;

    /// 🔥 LOCAL CHECK
    if (_alreadyApplied) {
      AppSnackbar.showError(context, "Already applied");
      return;
    }

    /// 🔥 FIRESTORE CHECK
    final existing = await FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: job.id)
        .where('seekerId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      AppSnackbar.showError(context, "Already applied");
      return;
    }

    setState(() => _applying = true);

    /// 🔥 GET USER DATA
    final userDoc =
        await _fire.collection('users').doc(user.uid).get();

    final userData = userDoc.data() ?? {};

    final String seekerName =
        (userData['fullName'] ?? 'User').toString();

    /// 🔥 STEP 1: ADD APPLICATION (MAIN LOGIC)
    await FirebaseFirestore.instance.collection('applications').add({
      'jobId': job.id,
      'jobTitle': job.title,
      'seekerId': user.uid,
      'employerId': job.postedBy,
      'name': seekerName,
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    await _notificationService.createNotification(
  userId: job.postedBy,
  type: "application",
  title: "New Application",
  body: "$seekerName applied for ${job.title}",
  jobId: job.id,
  jobTitle: job.title,
  senderId: user.uid,
  senderName: seekerName,
);

    /// 🔥 STEP 2: CHAT (OPTIONAL - DON'T BREAK FLOW)
    try {
  final employerId = job.postedBy;
  final seekerId = user.uid;

  final threadId = await _chatService.createOrGetThread(
  seekerId: user.uid,
  employerId: job.postedBy,
  seekerName: seekerName,
  employerName: job.postedByName,
  jobId: job.id,
  jobTitle: job.title,
  companyName: job.postedByName,
jobLocation: job.locationText ?? "",
jobScope: job.jobScope ?? "local",
);

await FirebaseFirestore.instance
    .collection('threads')
    .doc(threadId)
    .update({
  "jobTitle": job.title,
  "companyName": job.postedByName,
  "jobLocation": job.locationText ?? "",
  "jobScope": job.jobScope ?? "local",
  "employerId": job.postedBy,
  "employerName": job.postedByName,
  "seekerId": seekerId,
  "seekerName": seekerName,
});


} catch (e) {
  print("Chat creation failed: $e");
}

    /// ✅ SUCCESS
    if (!mounted) return;
    setState(() => _alreadyApplied = true);

    AppSnackbar.showSuccess(context, "Applied successfully");

  } catch (e) {
    print("Apply Error: $e");

    if (!mounted) return;
    AppSnackbar.showError(context, "Failed to apply");

  } finally {
    if (mounted) {
      setState(() => _applying = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final jobRef = _fire.collection('jobs').doc(widget.jobId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share("Check this job on Tieora");
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: jobRef.snapshots(),
        builder: (context, snap) {

          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }

          if (snap.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppSnackbar.showError(context, "Failed to load job");
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

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Job not found'));
          }

          final job = JobModel.fromMap(
            snap.data!.data() as Map<String, dynamic>,
            snap.data!.id,
          );

          return SingleChildScrollView(
            child: Column(
              children: [

                /// 🔥 MAIN CARD
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (job.isUrgent == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "URGENT",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        job.postedByName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(job.locationText ?? "")),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "₹ ${job.wage}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        children: [
                          _chip(job.jobScope ?? "Local"),
                          _chip(job.category),
                        ],
                      ),
                    ],
                  ),
                ),

                _infoCard(job),
                _descriptionCard(job),

                const SizedBox(height: 20),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(job),
                      icon: const Icon(Icons.chat),
                      label: const Text("Message Employer"),
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _infoCard(JobModel job) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoRow(Icons.attach_money, "Salary", "₹ ${job.wage}"),
          _infoRow(Icons.work, "Job Type", job.jobScope ?? "Local"),
          _infoRow(Icons.category, "Category", job.category),
        ],
      ),
    );
  }

  Widget _descriptionCard(JobModel job) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Job Description",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(job.description),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text("$title: "),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final currentUserId = _auth.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: _fire.collection('jobs').doc(widget.jobId).snapshots(),
      builder: (context, snap) {

        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox();
        }

        final job = JobModel.fromMap(
          snap.data!.data() as Map<String, dynamic>,
          snap.data!.id,
        );

        if (currentUserId == job.postedBy) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _alreadyApplied || _applying
                ? null
                : () => _applyToJob(job),
            child: _alreadyApplied
                ? const Text("Applied")
                : _applying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Apply Now"),
          ),
        );
      },
    );
  }
}