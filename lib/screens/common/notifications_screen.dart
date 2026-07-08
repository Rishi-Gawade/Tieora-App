import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_snackbar.dart';

import '../seeker/jobs/job_detail_screen.dart';
import '../common/message_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';

    return 'Just now';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'application':
        return Icons.work;
      case 'message':
        return Icons.chat;
      case 'accepted':
      case 'hired':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'application':
        return AppTheme.primaryBlue;
      case 'message':
        return Colors.purple;
      case 'accepted':
      case 'hired':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return AppTheme.primaryBlue;
    }
  }

  Future<void> _markAllAsRead(String uid, BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        doc.reference.update({'isRead': true});
      }
    } catch (e) {
      AppSnackbar.showError(context, "Failed to mark all as read");
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(uid, context),
            child: const Text(
              "Mark all",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snap) {

          /// 🔥 LOADING
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }

          /// 🔥 ERROR
          if (snap.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppSnackbar.showError(
                context,
                "Failed to load notifications",
              );
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

          /// 🔥 EMPTY
          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_none,
              title: "No notifications yet",
              subtitle: "We’ll notify you when something happens",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data =
                  doc.data() as Map<String, dynamic>? ?? {};

              final String senderName =
                  (data['senderName'] ?? '').toString();

              final String type =
                  (data['type'] ?? 'notification').toString();

              /// 🔥 FIXED TITLE LOGIC
              String title = (data['title'] ?? '').toString();

              if (title.isEmpty) {
                if (type == "message") {
                  title = "New Message";
                } else if (type == "application") {
                  title = "New Application";
                } else {
                  title = senderName.isNotEmpty
                      ? senderName
                      : "Notification";
                }
              }

              /// 🔥 FIXED BODY
              String body =
                  (data['body'] ?? data['message'] ?? '')
                      .toString();

              if (type == "message" &&
              senderName.isNotEmpty &&
              body.isNotEmpty &&
              !body.startsWith(senderName)) {
            body = "$senderName: $body";
          }

              final String jobTitle =
                  (data['jobTitle'] ?? '').toString();

              final String jobId =
                  (data['jobId'] ?? '').toString();

              final String? senderId =
                  data['senderId']?.toString();

              final bool isRead =
                  data['isRead'] == true;

              DateTime? createdAt;
              if (data['createdAt'] is Timestamp) {
                createdAt =
                    (data['createdAt'] as Timestamp).toDate();
              }

              final timeLabel =
                  createdAt != null ? _timeAgo(createdAt) : '';

              final color = _colorForType(type);

              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () async {

                  try {
                    if (!isRead) {
                      await doc.reference
                          .update({'isRead': true});
                    }
                  } catch (_) {}

                  /// MESSAGE
                  if (type == "message" &&
                      senderId != null &&
                      jobId.isNotEmpty &&
                      context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageDetailScreen(
                          threadId: jobId,
                          jobTitle: jobTitle,
                          otherUserId: senderId,
                        ),
                      ),
                    );
                  }

                  /// APPLICATION
                  else if (jobId.isNotEmpty &&
                      context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            JobDetailScreen(jobId: jobId),
                      ),
                    );
                  }
                },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : color.withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: color.withOpacity(.12),
                          child: Icon(
                            _iconForType(type),
                            color: color,
                            size: 28,
                          ),
                        ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                           Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                            if (body.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 2),
                                child: Text(
                                  body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                            if (jobTitle.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4),
                                child: Text(
                                  jobTitle,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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