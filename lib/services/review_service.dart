import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a review for a vendor
  Future<void> submitVendorReview({
    required String userId,
    required String userName,
    required String vendorId,
    required double rating,
    String? comment,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if user has already reviewed this vendor
      final existingReview = await _firestore
          .collection('reviews')
          .where('user_id', isEqualTo: userId)
          .where('vendor_id', isEqualTo: vendorId)
          .where('menu_item_id', isNull: true)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        await _firestore.collection('reviews').doc(existingReview.docs.first.id).update({
          'rating': rating,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': metadata,
        });
      } else {
        // Create new review
        final review = ReviewModel(
          id: '', // Firestore will generate this
          userId: userId,
          userName: userName,
          vendorId: vendorId,
          rating: rating,
          comment: comment,
          timestamp: DateTime.now(),
          metadata: metadata,
        );

        await _firestore.collection('reviews').add(review.toMap());
      }

      // Update vendor rating
      await _updateVendorRating(vendorId);

      if (kDebugMode) {
        print('Vendor review submitted: $rating stars for vendor $vendorId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting vendor review: $e');
      }
      rethrow;
    }
  }

  // Submit a review for a menu item
  Future<void> submitMenuItemReview({
    required String userId,
    required String userName,
    required String vendorId,
    required String menuItemId,
    required double rating,
    String? comment,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if user has already reviewed this menu item
      final existingReview = await _firestore
          .collection('reviews')
          .where('user_id', isEqualTo: userId)
          .where('menu_item_id', isEqualTo: menuItemId)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        await _firestore.collection('reviews').doc(existingReview.docs.first.id).update({
          'rating': rating,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': metadata,
        });
      } else {
        // Create new review
        final review = ReviewModel(
          id: '', // Firestore will generate this
          userId: userId,
          userName: userName,
          vendorId: vendorId,
          menuItemId: menuItemId,
          rating: rating,
          comment: comment,
          timestamp: DateTime.now(),
          metadata: metadata,
        );

        await _firestore.collection('reviews').add(review.toMap());
      }

      // Update menu item rating
      await _updateMenuItemRating(menuItemId);

      if (kDebugMode) {
        print('Menu item review submitted: $rating stars for item $menuItemId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting menu item review: $e');
      }
      rethrow;
    }
  }

  // Get vendor reviews
  Stream<List<ReviewModel>> getVendorReviews(String vendorId) {
    return _firestore
        .collection('reviews')
        .where('vendor_id', isEqualTo: vendorId)
        .where('menu_item_id', isNull: true)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid index requirements
          reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reviews;
        });
  }

  // Get menu item reviews
  Stream<List<ReviewModel>> getMenuItemReviews(String menuItemId) {
    return _firestore
        .collection('reviews')
        .where('menu_item_id', isEqualTo: menuItemId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid index requirements
          reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reviews;
        });
  }

  // Get user's reviews
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid index requirements
          reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reviews;
        });
  }

  // Get vendor rating summary
  Future<VendorRatingSummary> getVendorRatingSummary(String vendorId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('vendor_id', isEqualTo: vendorId)
          .where('menu_item_id', isNull: true)
          .get();

      if (reviews.docs.isEmpty) {
        return VendorRatingSummary(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
        );
      }

      double totalRating = 0.0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in reviews.docs) {
        final rating = (doc.data()['rating'] as num).toDouble();
        totalRating += rating;
        
        final ratingInt = rating.round();
        if (ratingInt >= 1 && ratingInt <= 5) {
          distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;
        }
      }

      final averageRating = totalRating / reviews.docs.length;

      return VendorRatingSummary(
        averageRating: averageRating,
        totalReviews: reviews.docs.length,
        ratingDistribution: distribution,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor rating summary: $e');
      }
      return VendorRatingSummary(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
      );
    }
  }

  // Get menu item rating summary
  Future<MenuItemRatingSummary> getMenuItemRatingSummary(String menuItemId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('menu_item_id', isEqualTo: menuItemId)
          .get();

      if (reviews.docs.isEmpty) {
        return MenuItemRatingSummary(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
        );
      }

      double totalRating = 0.0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in reviews.docs) {
        final rating = (doc.data()['rating'] as num).toDouble();
        totalRating += rating;
        
        final ratingInt = rating.round();
        if (ratingInt >= 1 && ratingInt <= 5) {
          distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;
        }
      }

      final averageRating = totalRating / reviews.docs.length;

      return MenuItemRatingSummary(
        averageRating: averageRating,
        totalReviews: reviews.docs.length,
        ratingDistribution: distribution,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting menu item rating summary: $e');
      }
      return MenuItemRatingSummary(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
      );
    }
  }

  // Check if user has reviewed a vendor
  Future<bool> hasUserReviewedVendor(String userId, String vendorId) async {
    try {
      final review = await _firestore
          .collection('reviews')
          .where('user_id', isEqualTo: userId)
          .where('vendor_id', isEqualTo: vendorId)
          .where('menu_item_id', isNull: true)
          .limit(1)
          .get();

      return review.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user has reviewed vendor: $e');
      }
      return false;
    }
  }

  // Check if user has reviewed a menu item
  Future<bool> hasUserReviewedMenuItem(String userId, String menuItemId) async {
    try {
      final review = await _firestore
          .collection('reviews')
          .where('user_id', isEqualTo: userId)
          .where('menu_item_id', isEqualTo: menuItemId)
          .limit(1)
          .get();

      return review.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user has reviewed menu item: $e');
      }
      return false;
    }
  }

  // Update vendor rating in vendor document
  Future<void> _updateVendorRating(String vendorId) async {
    try {
      final summary = await getVendorRatingSummary(vendorId);
      
      await _firestore.collection('vendors').doc(vendorId).update({
        'rating': summary.averageRating,
        'total_ratings': summary.totalReviews,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vendor rating: $e');
      }
    }
  }

  // Update menu item rating in menu item document
  Future<void> _updateMenuItemRating(String menuItemId) async {
    try {
      final summary = await getMenuItemRatingSummary(menuItemId);
      
      await _firestore.collection('menu_items').doc(menuItemId).update({
        'rating': summary.averageRating,
        'total_ratings': summary.totalReviews,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating menu item rating: $e');
      }
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (reviewDoc.exists) {
        final data = reviewDoc.data()!;
        final vendorId = data['vendor_id'];
        final menuItemId = data['menu_item_id'];

        // Delete the review
        await _firestore.collection('reviews').doc(reviewId).delete();

        // Update ratings
        if (menuItemId != null) {
          await _updateMenuItemRating(menuItemId);
        } else {
          await _updateVendorRating(vendorId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting review: $e');
      }
      rethrow;
    }
  }
}
