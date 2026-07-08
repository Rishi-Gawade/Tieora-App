import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../services/chat_service.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_snackbar.dart';

import 'message_detail_screen.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    final ChatService chatService = ChatService();

    return Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getThreads(uid),
        builder: (context, snapshot) {

          /// 🔥 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }

          /// 🔥 ERROR HANDLING
          if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppSnackbar.showError(
                context,
                "Something went wrong. Please try again.",
              );
            });

            return Center(
              child: ElevatedButton(
                onPressed: () {
                  // rebuild trigger
                  (context as Element).markNeedsBuild();
                },
                child: const Text("Retry"),
              ),
            );
          }

          final threads = snapshot.data?.docs ?? [];

          /// 🔥 EMPTY STATE
          if (threads.isEmpty) {
            return const AppEmptyState(
              icon: Icons.chat_bubble_outline,
              title: "No conversations yet",
              subtitle: "Start chatting by applying to jobs",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            itemCount: threads.length,
            itemBuilder: (context, index) {

              final doc = threads[index];
              final data =
                  doc.data() as Map<String, dynamic>? ?? {};

              final threadId = doc.id;

              /// 🔥 PARTICIPANTS
              final List<String> users =
                  List<String>.from(data['participants'] ?? []);

              String otherUserId = '';
              if (users.isNotEmpty) {
                try {
                  otherUserId =
                      users.firstWhere((id) => id != uid);
                } catch (_) {}
              }

              /// 🔥 USER NAME
              final Map names = data['userNames'] ?? {};
              final name = names[otherUserId] ?? "User";

              /// 🔥 JOB TITLE
              final String jobTitle =
                  data['jobTitle'] ?? "Job Chat";

              /// 🔥 LAST MESSAGE
              final lastMessage =
                  data['lastMessage'] ?? '';

              /// 🔥 TIME
              final Timestamp? ts =
                  data['lastMessageAt'] is Timestamp
                      ? data['lastMessageAt']
                      : null;

              final timeLabel =
                  ts != null ? _timeAgo(ts.toDate()) : '';

              /// 🔥 UNREAD COUNT
              final Map unreadMap =
                  data['unreadCount'] ?? {};

              final int unread =
                  unreadMap[uid] ?? 0;

              final bool hasUnread = unread > 0;

             return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (otherUserId.isEmpty) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageDetailScreen(
                        threadId: threadId,
                        jobTitle: jobTitle,
                        otherUserId: otherUserId,
                      ),
                    ),
                  );
                },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),

                 decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      /// ICON
                      CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(.10),
                      child: const Icon(
                        Icons.business,
                        color: AppTheme.primaryBlue,
                        size: 30,
                      ),
                    ),

                      const SizedBox(width: 14),

                      /// TEXT
                     Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                              /// Top Row
                              Row(
                                children: [

                                  Expanded(
                                    child: Text(
                                      jobTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      timeLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              /// Employer Name
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 10),

                              /// Last Message
                              Row(
                                children: [

                                  Expanded(
                                    child: Text(
                                      lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade800,
                                        fontWeight:
                                            hasUnread
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),

                                  if (hasUnread)
                                    Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      constraints: const BoxConstraints(
                                        minHeight: 24,
                                        minWidth: 24,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unread > 9 ? "9+" : "$unread",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
              ),
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';

    return 'now';
  }
}