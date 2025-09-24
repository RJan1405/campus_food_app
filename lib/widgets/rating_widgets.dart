import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool allowHalfRating;
  final ValueChanged<double>? onRatingChanged;
  final bool readOnly;

  const StarRating({
    Key? key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.allowHalfRating = false,
    this.onRatingChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        return GestureDetector(
          onTap: readOnly ? null : () {
            if (onRatingChanged != null) {
              double newRating = index + 1.0;
              if (allowHalfRating) {
                // For half rating, you could implement tap on left/right half
                onRatingChanged!(newRating);
              } else {
                onRatingChanged!(newRating);
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              _getStarIcon(index),
              size: size,
              color: _getStarColor(index),
            ),
          ),
        );
      }),
    );
  }

  IconData _getStarIcon(int index) {
    if (index < rating.floor()) {
      return Icons.star;
    } else if (index < rating.ceil() && allowHalfRating) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(int index) {
    if (index < rating.floor()) {
      return activeColor;
    } else if (index < rating.ceil() && allowHalfRating) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }
}

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final double size;
  final bool showReviewCount;
  final TextStyle? textStyle;

  const RatingDisplay({
    Key? key,
    required this.rating,
    this.totalReviews = 0,
    this.size = 16.0,
    this.showReviewCount = true,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(
          rating: rating,
          size: size,
          readOnly: true,
          activeColor: Colors.amber,
          inactiveColor: Colors.grey.shade300,
        ),
        if (showReviewCount && totalReviews > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: textStyle ?? TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingBar extends StatefulWidget {
  final double initialRating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<double> onRatingChanged;
  final bool allowHalfRating;

  const RatingBar({
    Key? key,
    this.initialRating = 0.0,
    this.maxRating = 5,
    this.size = 30.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    required this.onRatingChanged,
    this.allowHalfRating = false,
  }) : super(key: key);

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = index + 1.0;
              widget.onRatingChanged(_currentRating);
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                index < _currentRating ? Icons.star : Icons.star_border,
                size: widget.size,
                color: index < _currentRating ? widget.activeColor : widget.inactiveColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final String title;

  const RatingSummaryCard({
    Key? key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    this.title = 'Rating Summary',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Average rating display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    StarRating(
                      rating: averageRating,
                      size: 20,
                      readOnly: true,
                      activeColor: Colors.amber,
                      inactiveColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews reviews',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Rating distribution
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final rating = 5 - index;
                      final count = ratingDistribution[rating] ?? 0;
                      final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$rating',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.amber.withOpacity(0.7),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String userName;
  final double rating;
  final String? comment;
  final DateTime timestamp;
  final VoidCallback? onDelete;
  final bool canDelete;

  const ReviewCard({
    Key? key,
    required this.userName,
    required this.rating,
    this.comment,
    required this.timestamp,
    this.onDelete,
    this.canDelete = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      StarRating(
                        rating: rating,
                        size: 16,
                        readOnly: true,
                        activeColor: Colors.amber,
                        inactiveColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
                if (canDelete && onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    iconSize: 20,
                  ),
              ],
            ),
            if (comment != null && comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
