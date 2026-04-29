import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String? id;
  final String threadId;
  final String senderId;

  /// 🔥 EXISTING
  final String? senderName;

  final String message;
  final DateTime? timestamp;
  final List<String>? seenBy;

  /// 🔥 NEW (IMAGE SUPPORT)
  final String? imageUrl;
  final String type; // "text" or "image"

  MessageModel({
    this.id,
    required this.threadId,
    required this.senderId,
    this.senderName,
    required this.message,
    this.timestamp,
    this.seenBy,

    /// 🔥 NEW
    this.imageUrl,
    this.type = "text",
  });

  /// 🔹 Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      "threadId": threadId,
      "senderId": senderId,
      "senderName": senderName,
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "seenBy": seenBy ?? [],

      /// 🔥 NEW
      "imageUrl": imageUrl,
      "type": type,
    };
  }

  /// 🔹 From Firestore
  factory MessageModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    DateTime? safeTimestamp;

    final rawTimestamp = map['timestamp'];

    if (rawTimestamp is Timestamp) {
      safeTimestamp = rawTimestamp.toDate();
    }

    return MessageModel(
      id: id,
      threadId: map['threadId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      message: map['message'] ?? '',
      timestamp: safeTimestamp,
      seenBy: map['seenBy'] != null
          ? List<String>.from(map['seenBy'])
          : [],

      /// 🔥 NEW SAFE READ
      imageUrl: map['imageUrl'],
      type: map['type'] ?? "text",
    );
  }

  MessageModel copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? timestamp,
    List<String>? seenBy,

    /// 🔥 NEW
    String? imageUrl,
    String? type,
  }) {
    return MessageModel(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      seenBy: seenBy ?? this.seenBy,

      /// 🔥 NEW
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
    );
  }
}