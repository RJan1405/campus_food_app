import 'package:cloud_firestore/cloud_firestore.dart';

class RatingReviewModel {
  final String id;
  final String userId;
  final String userName; // Display name of reviewer
  final String targetId; // ID of vendor or menu item being reviewed
  final String targetType; // 'vendor' or 'menuItem'
  final double rating; // 1-5 star rating
  final String? reviewText;
  final DateTime timestamp;
  final List<String>? imageUrls; // Optional photos with review
  final bool isVerifiedPurchase; // If user has ordered from this vendor
  final String? orderId; // Associated order if applicable
  
  RatingReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.targetId,
    required this.targetType,
    required this.rating,
    this.reviewText,
    required this.timestamp,
    this.imageUrls,
    required this.isVerifiedPurchase,
    this.orderId,
  });
  
  factory RatingReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return RatingReviewModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      targetId: data['target_id'] ?? '',
      targetType: data['target_type'] ?? 'vendor',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewText: data['review_text'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrls: data['image_urls'] != null 
          ? List<String>.from(data['image_urls']) 
          : null,
      isVerifiedPurchase: data['is_verified_purchase'] ?? false,
      orderId: data['order_id'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'target_id': targetId,
      'target_type': targetType,
      'rating': rating,
      'review_text': reviewText,
      'timestamp': Timestamp.fromDate(timestamp),
      'image_urls': imageUrls,
      'is_verified_purchase': isVerifiedPurchase,
      'order_id': orderId,
    };
  }
}