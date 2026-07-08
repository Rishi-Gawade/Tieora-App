import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 NEW

import '../../../models/message_model.dart';
import '../../../services/chat_service.dart';
import '../../../core/widgets/app_loader.dart';
import '../../core/widgets/app_rating.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MessageDetailScreen extends StatefulWidget {
  final String threadId;
  final String jobTitle;
  final String otherUserId;

  const MessageDetailScreen({
    super.key,
    required this.threadId,
    required this.jobTitle,
    required this.otherUserId,
  });

  @override
  State<MessageDetailScreen> createState() =>
      _MessageDetailScreenState();
}

class _MessageDetailScreenState
    extends State<MessageDetailScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final ChatService _chatService = ChatService();

  String get _currentUserId =>
      FirebaseAuth.instance.currentUser!.uid;

  bool _isSending = false;

  String _senderName = "User";

  @override
void initState() {
  super.initState();

  _loadUserName();

  _chatService.markMessagesAsSeen(
    threadId: widget.threadId,
    userId: _currentUserId,
  );
}

Future<void> _loadUserName() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .get();

    final data =
        doc.data() as Map<String, dynamic>? ?? {};

    _senderName =
        data['fullName'] ?? "User";
  } catch (e) {
    debugPrint("Name Load Error: $e");
  }
}

  

@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();

  /// 🔥 ADD THIS LINE (IMPORTANT)
  _chatService.setTyping(
    threadId: widget.threadId,
    userId: _currentUserId,
    isTyping: false,
  );

  super.dispose();
}

  /// 🔥 SEND MESSAGE
  Future<void> _sendMessage() async {
  final text = _controller.text.trim();

  if (text.isEmpty || _isSending) return;

  setState(() => _isSending = true);

  try {
    _controller.clear();

    final message = MessageModel(
      threadId: widget.threadId,
      senderId: _currentUserId,
      senderName: _senderName,
      message: text,
    );

    await _chatService.sendMessage(message);

    await _chatService.setTyping(
      threadId: widget.threadId,
      userId: _currentUserId,
      isTyping: false,
    );

    _scrollToBottom();
  } catch (e) {
    debugPrint("MESSAGE SCREEN ERROR => $e");

    AppSnackbar.showError(
      context,
      e.toString(),
    );
  } finally {
    if (mounted) {
      setState(() => _isSending = false);
    }
  }
}

    /// 🔥 NEW: IMAGE PICK FUNCTION
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    try {
      final url = await _chatService.uploadChatImage(file);

      await _chatService.sendImageMessage(
        threadId: widget.threadId,
        senderId: _currentUserId,
        senderName: _senderName,
        imageUrl: url,
      );

      _scrollToBottom();
    } catch (e) {
      AppSnackbar.showError(context, "Image send failed");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';

    final hour =
        dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final minute =
        dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    return "$hour:$minute $ampm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection('users')
      .doc(widget.otherUserId)
      .get(),
  builder: (context, snap) {

    String name = widget.jobTitle; // fallback
    double rating = 0;
    int total = 0;

    if (snap.hasData && snap.data!.exists) {
      final data = snap.data!.data() as Map<String, dynamic>? ?? {};

      name = (data['fullName'] ?? name).toString();
      rating = (data['rating'] ?? 0).toDouble();
      total = data['totalRatings'] ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 👤 NAME
        Text(
          name,
          style: const TextStyle(fontSize: 16),
        ),

        /// ⭐ RATING
        if (total > 0)
          AppRating(
            rating: rating,
            totalRatings: total,
            size: 12,
          ),
      ],
    );
  },
),
      ),
      body: Column(
        children: [
          

          /// 🔥 TYPING INDICATOR (NEW)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('threads')
                .doc(widget.threadId)
                .snapshots(),
            builder: (context, snap) {

              final data =
                  snap.data?.data() as Map<String, dynamic>? ?? {};

              final typing = data['typing'] ?? {};

              final isOtherTyping =
                  typing[widget.otherUserId] == true;

              if (!isOtherTyping) return const SizedBox();

              return const Padding(
                padding: EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  "Typing...",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          ),

          /// 🔥 MESSAGES LIST
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream:
                  _chatService.getMessages(widget.threadId),
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const AppLoader();
                }

                if (snapshot.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppSnackbar.showError(
                      context,
                      "Something went wrong. Try again.",
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

                final messages = snapshot.data ?? [];

                if (messages.isNotEmpty) {
                  _chatService.markMessagesAsSeen(
                    threadId: widget.threadId,
                    userId: _currentUserId,
                  );

                  _scrollToBottom();
                }

                if (messages.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: "Start the conversation",
                    subtitle: "Say hello 👋",
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {

                    final msg = messages[index];
                    final isMe =
                        msg.senderId == _currentUserId;

                    final seenBy =
                        msg.seenBy ?? [];

                    final isSeen =
                        seenBy.contains(widget.otherUserId);

                    return _chatBubble(
                      text: msg.message,
                      isMe: isMe,
                      time: _formatTime(msg.timestamp),
                      isSeen: isSeen,
                    );
                  },
                );
              },
            ),
          ),

          /// 🔥 INPUT
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                children: [

                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,

                        /// 🔥 DETECT TYPING (NEW)
                        onChanged: (value) {
                          _chatService.setTyping(
                            threadId: widget.threadId,
                            userId: _currentUserId,
                            isTyping: value.isNotEmpty,
                          );
                        },

                        onSubmitted: (_) => _sendMessage(),
                        decoration:
                            const InputDecoration(
                          hintText:
                              "Type a message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: _isSending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: _sendMessage,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble({
    required String text,
    required bool isMe,
    required String time,
    required bool isSeen,
  }) {
    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [

          Container(
            margin:
                const EdgeInsets.symmetric(
                    vertical: 6),
            padding:
                const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10),
            constraints:
                const BoxConstraints(
                    maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.green
                  : Colors.grey.shade200,
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    const Radius.circular(18),
                topRight:
                    const Radius.circular(18),
                bottomLeft:
                    Radius.circular(
                        isMe ? 18 : 4),
                bottomRight:
                    Radius.circular(
                        isMe ? 4 : 18),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (time.isNotEmpty)
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),

              if (isMe)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 6),
                  child: Icon(
                    isSeen
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: isSeen
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}