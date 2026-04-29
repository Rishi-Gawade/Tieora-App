import 'package:flutter/material.dart';

class AppRating extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;

  const AppRating({
    super.key,
    required this.rating,
    required this.totalRatings,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (totalRatings == 0) {
      return Text(
        "No ratings yet",
        style: TextStyle(
          fontSize: size - 2,
          color: Colors.grey,
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "($totalRatings)",
          style: TextStyle(
            fontSize: size - 2,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}