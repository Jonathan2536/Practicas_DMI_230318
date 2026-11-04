import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showScore;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.showScore = true,
  });

  @override
  Widget build(BuildContext context) {
    final fiveStarRating = (rating.clamp(0, 10) / 2).toDouble();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 5; index++)
          Icon(
            fiveStarRating >= index + 1
                ? Icons.star
                : fiveStarRating >= index + 0.5
                ? Icons.star_half
                : Icons.star_border,
            size: size,
            color: Colors.amber.shade700,
          ),
        if (showScore) ...[
          const SizedBox(width: 4),
          Text(rating.toStringAsFixed(1)),
        ],
      ],
    );
  }
}
