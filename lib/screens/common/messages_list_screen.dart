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
            padding: const EdgeInsets.all(16),
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

              return GestureDetector(
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
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppTheme.defaultRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      /// ICON
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.work,
                          color: AppTheme.primaryBlue,
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            /// 👤 NAME
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 2),

                            /// 💼 JOB TITLE
                            Text(
                              jobTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// 💬 LAST MESSAGE
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      /// TIME + BADGE
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [

                          Text(
                            timeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),

                          if (hasUnread)
                            Container(
                              margin:
                                  const EdgeInsets.only(top: 6),
                              padding:
                                  const EdgeInsets.all(6),
                              decoration:
                                  const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';

    return 'now';
  }
}