import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationWriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 CREATE NOTIFICATION (PRO + SAFE)
  Future<void> createNotification({
    required String userId, // 🔥 receiver

    /// 🔥 TYPE
    required String type, // application | message | hired | rejected

    /// 🔥 CONTENT
    required String title,
    required String body,

    /// 🔥 NAVIGATION DATA
    String? jobId,
    String? jobTitle,
    String? applicantId,

    /// 🔥 CHAT SUPPORT
    String? senderId,
    String? senderName,
  }) async {
    try {
      final docRef = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc();

      /// 🔥 SAFE FALLBACKS
      final safeSenderName =
          (senderName != null && senderName.trim().isNotEmpty)
              ? senderName
              : "User";

      final safeSenderId =
          (senderId != null && senderId.isNotEmpty)
              ? senderId
              : null;

      await docRef.set({
        /// 🔥 ID
        'notificationId': docRef.id,

        /// 🔥 TYPE
        'type': type,

        /// 🔥 CONTENT
        'title': title,
        'body': body,

        /// 🔥 NAVIGATION
        'jobId': jobId ?? "",
        'jobTitle': jobTitle ?? "",
        'applicantId': applicantId ?? "",

        /// 🔥 FIXED CHAT DATA
        'senderId': safeSenderId,
        'senderName': safeSenderName,

        /// 🔥 STATUS
        'isRead': false,

        /// 🔥 TIMESTAMP
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to create notification: $e");
    }
  }
}