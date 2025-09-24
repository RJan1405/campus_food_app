import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String vendorId;
  final String? menuItemId;
  final double rating;
  final String? comment;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.vendorId,
    this.menuItemId,
    required this.rating,
    this.comment,
    required this.timestamp,
    this.metadata,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      vendorId: data['vendor_id'] ?? '',
      menuItemId: data['menu_item_id'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'vendor_id': vendorId,
      'menu_item_id': menuItemId,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

class VendorRatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // rating -> count

  VendorRatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });
}

class MenuItemRatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  MenuItemRatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });
}
