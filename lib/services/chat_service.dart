import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🔥 NEW

import '../models/message_model.dart';
import 'notification_write_service.dart';

class ChatService {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  final NotificationWriteService _notificationService =
      NotificationWriteService();

  CollectionReference get threads => _fire.collection('threads');
  CollectionReference get messages => _fire.collection('messages');

  /// =========================
  /// 🔥 CREATE OR GET THREAD
  /// =========================
  Future<String> createOrGetThread({
  required String seekerId,
  required String employerId,
  required String seekerName,
  required String employerName,
  required String jobId,
  required String jobTitle,
  required String companyName,
  required String jobLocation,
  required String jobScope,
}) async {
    try {
      final sortedIds = [seekerId, employerId]..sort();

      final threadKey =
          "${sortedIds[0]}_${sortedIds[1]}_$jobId";

      final existingThread = await threads.doc(threadKey).get();

      if (existingThread.exists) {
  await threads.doc(threadKey).update({
    "jobTitle": jobTitle,
    "companyName": companyName,
    "jobLocation": jobLocation,
    "jobScope": jobScope,
    "employerName": employerName,
    "seekerName": seekerName,
  });

  return threadKey;
}

      await threads.doc(threadKey).set({
  "participants": sortedIds,

  "userNames": {
    seekerId: seekerName,
    employerId: employerName,
  },

  "jobId": jobId,
  "jobTitle": jobTitle,
  "companyName": companyName,
  "jobLocation": jobLocation,
  "jobScope": jobScope,

  "employerId": employerId,
  "employerName": employerName,

  "seekerId": seekerId,
  "seekerName": seekerName,

  "lastMessage": "",
  "lastMessageAt": FieldValue.serverTimestamp(),
  "lastSenderId": "",

  "typing": {},

  "unreadCount": {
    seekerId: 0,
    employerId: 0,
  },

  "createdAt": FieldValue.serverTimestamp(),
});

      return threadKey;
    } catch (e) {
      throw Exception("Thread error: $e");
    }
  }

  /// =========================
  /// 🔥 IMAGE UPLOAD (NEW)
  /// =========================
  Future<String> uploadChatImage(File file) async {
    try {
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString();

      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images/$fileName');

      await ref.putFile(file);

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }

  /// =========================
  /// 🔥 SEND MESSAGE (UPDATED)
  /// =========================
 // ONLY FIXES APPLIED — NO LOGIC CHANGE

Future<void> sendMessage(MessageModel message) async {
  try {
    final safeSenderName =
        (message.senderName != null &&
                message.senderName!.trim().isNotEmpty)
            ? message.senderName!
            : "User";

    /// 🔥 FIX 1: SAFE MESSAGE
    final safeMessage = message.message ?? "";

    /// 🔥 FIX 2: SAFE LAST MESSAGE
    final lastMessageText =
        message.type == "image" ? "📸 Image" : safeMessage;

    await messages.add({
      "threadId": message.threadId,
      "senderId": message.senderId,
      "senderName": safeSenderName,
      "message": safeMessage, // ✅ FIXED
      "imageUrl": message.imageUrl,
      "type": message.type,
      "timestamp": FieldValue.serverTimestamp(),
      "seenBy": [message.senderId],
    });

    final threadDoc =
        await threads.doc(message.threadId).get();

    if (!threadDoc.exists) return;

    final data =
        threadDoc.data() as Map<String, dynamic>? ?? {};

    final List participants =
        data['participants'] ?? [];

    Map<String, dynamic> unread =
        Map<String, dynamic>.from(
            data['unreadCount'] ?? {});

    String? receiverId;

    for (var user in participants) {
      if (user != message.senderId) {
        receiverId = user;
        unread[user] = (unread[user] ?? 0) + 1;
      }
    }

    await threads.doc(message.threadId).update({
      "lastMessage": lastMessageText,
      "lastMessageAt": FieldValue.serverTimestamp(),
      "lastSenderId": message.senderId,
      "unreadCount": unread,
    });

   if (receiverId != null) {
  /// Create Firestore notification
  await _notificationService.createNotification(
    userId: receiverId,
    type: "message",
    title: "New Message",
    body: "$safeSenderName: $lastMessageText",
    jobId: message.threadId,
    jobTitle: "",
    senderId: message.senderId,
    senderName: safeSenderName,
  );

  /// Get receiver token
  final userDoc = await _fire
      .collection('users')
      .doc(receiverId)
      .get();

  final fcmToken = userDoc.data()?['fcmToken'];

  /// Push notification should NEVER break message sending
  if (fcmToken != null &&
      fcmToken.toString().trim().isNotEmpty) {
    try {
      await _sendPushNotification(
        token: fcmToken,
        title: "New Message",
        body: "$safeSenderName: $lastMessageText",
      );
    } catch (e) {
      debugPrint(
        "🔥 Push Notification Error: $e",
      );
    }
  }
}
} catch (e, stackTrace) {
  debugPrint("🔥 SEND MESSAGE ERROR: $e");
  debugPrint("🔥 STACKTRACE: $stackTrace");
  rethrow;
}
}
  /// =========================
  /// 🔥 SEND IMAGE MESSAGE (NEW)
  /// =========================
  Future<void> sendImageMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    required String imageUrl,
  }) async {
    final message = MessageModel(
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      message: "",
      imageUrl: imageUrl,
      type: "image",
    );

    await sendMessage(message);
  }

  /// =========================
  /// 🔥 PUSH NOTIFICATION
  /// =========================
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      const String serverKey = "YOUR_SERVER_KEY_HERE";

      await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "key=$serverKey",
        },
        body: jsonEncode({
          "to": token,
          "notification": {
            "title": title,
            "body": body,
          },
          "priority": "high",
        }),
      );
    } catch (e) {
      debugPrint("Push send error: $e");
    }
  }

  /// =========================
  /// 🔥 REALTIME STREAM
  /// =========================
  Stream<List<MessageModel>> getMessages(String threadId) {
    return messages
        .where('threadId', isEqualTo: threadId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      } catch (e) {
        debugPrint("Message parse error: $e");
        return [];
      }
    });
  }

  /// =========================
  /// 🔥 MARK AS SEEN
  /// =========================
  Future<void> markMessagesAsSeen({
    required String threadId,
    required String userId,
  }) async {
    try {
      final snapshot = await messages
          .where('threadId', isEqualTo: threadId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          "seenBy": FieldValue.arrayUnion([userId]),
        });
      }

      await threads.doc(threadId).update({
        "unreadCount.$userId": 0,
      });
    } catch (e) {
      debugPrint("Seen error: $e");
    }
  }

  /// =========================
  /// 🔥 TYPING
  /// =========================
  Future<void> setTyping({
    required String threadId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await threads.doc(threadId).set({
        "typing": {
          userId: isTyping,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Typing error: $e");
    }
  }

  /// =========================
  /// 🔥 GET THREADS
  /// =========================
  Stream<QuerySnapshot> getThreads(String userId) {
    return threads
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }
}