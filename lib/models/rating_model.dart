import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String jobId;
  final double rating;
  final String review;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.jobId,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'jobId': jobId,
      'rating': rating,
      'review': review,
      'createdAt': createdAt,
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map, String id) {
    return RatingModel(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      jobId: map['jobId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      review: map['review'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}