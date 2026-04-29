import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../common/message_detail_screen.dart';
import '../../../services/chat_service.dart';
import '../../common/rating_screen.dart';

import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_snackbar.dart';

class ApplicantDetailScreen extends StatefulWidget {
  final String jobId;
  final String seekerId;
  final String name;
  final String jobTitle;
  final String applicantId;

  const ApplicantDetailScreen({
    super.key,
    required this.jobId,
    required this.seekerId,
    required this.name,
    required this.jobTitle,
    required this.applicantId,
  });

  @override
  State<ApplicantDetailScreen> createState() =>
      _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState
    extends State<ApplicantDetailScreen> {

  final ChatService _chatService = ChatService();

  bool _loadingComplete = false;

  /// 🔥 STATUS UPDATE
  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicantId)
          .update({'status': newStatus});

      if (!mounted) return;

      Navigator.pop(context);

      AppSnackbar.showSuccess(
          context, "Application $newStatus");

    } catch (e) {
      AppSnackbar.showError(
          context, "Failed to update status");
    }
  }

  /// 🔥 MARK COMPLETED (SAFE)
 Future<void> _markCompleted() async {
  if (_loadingComplete) return;

  setState(() => _loadingComplete = true);

  try {
    /// 🔥 STEP 1: UPDATE STATUS
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(widget.applicantId)
        .update({
      'status': 'completed',
      'isCompleted': true,
    });

    /// 🔔 STEP 2: ADD NOTIFICATION (NEW)
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.seekerId)
        .collection('items')
        .add({
      "type": "completed",
      "title": "Job Completed",
      "body": "Please rate your experience",
      "jobId": widget.jobId,
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    if (!mounted) return;

    /// ✅ STEP 3: FEEDBACK
    AppSnackbar.showSuccess(context, "Job marked as completed");

    /// 🚀 STEP 4: NAVIGATE TO RATING
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          jobId: widget.jobId,
          toUserId: widget.seekerId,
        ),
      ),
    );

  } catch (e) {
    AppSnackbar.showError(context, "Failed to complete job");
  } finally {
    if (mounted) {
      setState(() => _loadingComplete = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Applicant Details"),
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('applications')
            .doc(widget.applicantId)
            .get(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const AppLoader();
          }

          if (snapshot.hasError) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  (context as Element).markNeedsBuild();
                },
                child: const Text("Retry"),
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
                child: Text("Applicant not found"));
          }

          final applicantData =
              snapshot.data!.data()
                      as Map<String, dynamic>? ??
                  {};

          final String seekerId =
              applicantData['seekerId']?.toString() ?? "";

          if (seekerId.isEmpty) {
            return const Center(
                child: Text("Invalid applicant data"));
          }

          final status =
              applicantData["status"]?.toString() ??
                  "pending";

          final isCompleted =
              applicantData["isCompleted"] ?? false;

          final bool isPending = status == 'pending';
          final bool isAccepted = status == 'accepted';

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(seekerId)
                .get(),
            builder: (context, userSnap) {

              if (userSnap.connectionState ==
                  ConnectionState.waiting) {
                return const AppLoader();
              }

              final userData =
                  userSnap.data?.data()
                          as Map<String, dynamic>? ??
                      {};

              final name = userData["fullName"] ??
                  applicantData["name"] ??
                  "No Name";

              final email = userData["email"] ??
                  applicantData["email"] ??
                  "Not provided";

              final phone = userData["phone"] ??
                  applicantData["phone"] ??
                  "Not provided";

              final location = userData["locationText"] ??
                  applicantData["locationText"] ??
                  "Not provided";

              final profileImage =
                  userData["profileImage"];

              List skills = [];
              if (userData["skills"] is List) {
                skills = userData["skills"];
              }

              Color statusColor;
              switch (status.toLowerCase()) {
                case "accepted":
                  statusColor = Colors.green;
                  break;
                case "rejected":
                  statusColor = Colors.red;
                  break;
                case "completed":
                  statusColor = Colors.blue;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  /// PROFILE
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundImage:
                                profileImage != null
                                    ? NetworkImage(
                                        profileImage)
                                    : null,
                            child: profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 42)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionCard(
                    title: "Contact Information",
                    child: Column(
                      children: [
                        _infoRow("Phone", phone),
                        _infoRow("Email", email),
                        _infoRow("Location", location),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    title: "Skills",
                    child: skills.isNotEmpty
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: skills
                                .map((s) => Chip(
                                    label:
                                        Text(s.toString())))
                                .toList(),
                          )
                        : const Text("No skills provided"),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    title: "Application Status",
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CHAT
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chat),
                    label:
                        const Text("Message Applicant"),
                    onPressed: () async {
                      final employer =
                          FirebaseAuth.instance
                              .currentUser;
                      if (employer == null) return;

                      final threadId =
                          await _chatService
                              .createOrGetThread(
                        employer.uid,
                        seekerId,
                        "Employer",
                        name,
                        widget.jobId,
                      );

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MessageDetailScreen(
                              threadId: threadId,
                              jobTitle:
                                  widget.jobTitle,
                              otherUserId: seekerId,
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  /// ACCEPT / REJECT
                  if (isPending) ...[
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _updateStatus('rejected'),
                            child:
                                const Text("Reject"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _updateStatus('accepted'),
                            child:
                                const Text("Accept"),
                          ),
                        ),
                      ],
                    ),
                  ],

                  /// MARK COMPLETED
                  if (isAccepted && !isCompleted)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loadingComplete
                              ? null
                              : _markCompleted,
                          child: _loadingComplete
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Mark as Completed"),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    );
  }
}