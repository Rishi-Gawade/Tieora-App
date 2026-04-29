import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  Future<void> submitRating({
    required String fromUserId,
    required String toUserId,
    required String jobId,
    required double rating,
    required String review,
  }) async {

    /// 🔥 SAVE RATING
    await _fire.collection('ratings').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'jobId': jobId,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
    });

    /// 🔥 UPDATE USER RATING
    final userRef = _fire.collection('users').doc(toUserId);

    await _fire.runTransaction((tx) async {
      final snap = await tx.get(userRef);

      final data = snap.data() ?? {};

      final double currentRating =
          (data['rating'] ?? 0).toDouble();

      final int totalRatings =
          (data['totalRatings'] ?? 0);

      final double newRating =
          ((currentRating * totalRatings) + rating) /
              (totalRatings + 1);

      tx.update(userRef, {
        'rating': newRating,
        'totalRatings': totalRatings + 1,
      });
    });
  }
}