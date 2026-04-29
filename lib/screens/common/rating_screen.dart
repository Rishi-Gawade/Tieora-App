import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../services/rating_service.dart';

class RatingScreen extends StatefulWidget {
  final String toUserId;
  final String jobId;

  const RatingScreen({
    super.key,
    required this.toUserId,
    required this.jobId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double rating = 0;
  final TextEditingController _controller = TextEditingController();
  bool loading = false;

  final RatingService _service = RatingService();

  Future<void> _submit() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      AppSnackbar.showError(context, "User not logged in");
      return;
    }

    final currentUserId = currentUser.uid;

    /// 🔥 VALIDATION
    if (rating == 0) {
      AppSnackbar.showError(context, "Please select rating");
      return;
    }

    try {
      /// 🔥 PREVENT DOUBLE RATING
      final existing = await FirebaseFirestore.instance
          .collection('ratings')
          .where('fromUserId', isEqualTo: currentUserId)
          .where('jobId', isEqualTo: widget.jobId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        AppSnackbar.showError(context, "Already rated");
        return;
      }

      setState(() => loading = true);

      /// 🔥 SUBMIT RATING
      await _service.submitRating(
        fromUserId: currentUserId, // ✅ FIXED
        toUserId: widget.toUserId,
        jobId: widget.jobId,
        rating: rating,
        review: _controller.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      AppSnackbar.showSuccess(context, "Rating submitted");

    } catch (e) {
      AppSnackbar.showError(context, "Failed to submit rating");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rate User")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const Text(
              "How was your experience?",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            /// ⭐ STAR RATING
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() => rating = i + 1.0);
                  },
                );
              }),
            ),

            /// 📝 REVIEW FIELD
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Write a review (optional)",
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
}