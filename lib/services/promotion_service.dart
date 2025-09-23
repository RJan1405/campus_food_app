import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/promotion_model.dart';

class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _promotionsCollection = 
      FirebaseFirestore.instance.collection('promotions');
  
  // Get all promotions for a vendor
  Future<List<PromotionModel>> getVendorPromotions(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _promotionsCollection
          .where('vendor_id', isEqualTo: vendorId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor promotions: $e');
      }
      throw Exception('Failed to get vendor promotions: $e');
    }
  }
  
  // Get active promotions for a vendor
  Future<List<PromotionModel>> getActiveVendorPromotions(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _promotionsCollection
          .where('vendor_id', isEqualTo: vendorId)
          .where('is_active', isEqualTo: true)
          .get();
      
      List<PromotionModel> promotions = querySnapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .toList();
      
      // Filter out expired promotions
      DateTime now = DateTime.now();
      return promotions.where((promo) => 
          promo.startDate.isBefore(now) && 
          promo.endDate.isAfter(now) &&
          (promo.usageLimit == null || promo.usageCount < promo.usageLimit!)
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active vendor promotions: $e');
      }
      throw Exception('Failed to get active vendor promotions: $e');
    }
  }
  
  // Get promotion by ID
  Future<PromotionModel> getPromotionById(String promotionId) async {
    try {
      DocumentSnapshot doc = await _promotionsCollection.doc(promotionId).get();
      
      if (!doc.exists) {
        throw Exception('Promotion not found');
      }
      
      return PromotionModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting promotion: $e');
      }
      throw Exception('Failed to get promotion: $e');
    }
  }
  
  // Create a new promotion
  Future<String> createPromotion(PromotionModel promotion) async {
    try {
      DocumentReference docRef = await _promotionsCollection.add(promotion.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating promotion: $e');
      }
      throw Exception('Failed to create promotion: $e');
    }
  }
  
  // Update a promotion
  Future<void> updatePromotion(PromotionModel promotion) async {
    try {
      await _promotionsCollection.doc(promotion.id).update(promotion.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating promotion: $e');
      }
      throw Exception('Failed to update promotion: $e');
    }
  }
  
  // Delete a promotion
  Future<void> deletePromotion(String promotionId) async {
    try {
      await _promotionsCollection.doc(promotionId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting promotion: $e');
      }
      throw Exception('Failed to delete promotion: $e');
    }
  }
  
  // Toggle promotion active status
  Future<void> togglePromotionStatus(String promotionId, bool isActive) async {
    try {
      await _promotionsCollection.doc(promotionId).update({
        'is_active': isActive,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling promotion status: $e');
      }
      throw Exception('Failed to toggle promotion status: $e');
    }
  }
  
  // Increment promotion usage count
  Future<void> incrementPromotionUsage(String promotionId) async {
    try {
      // Get current promotion
      DocumentSnapshot doc = await _promotionsCollection.doc(promotionId).get();
      
      if (!doc.exists) {
        throw Exception('Promotion not found');
      }
      
      PromotionModel promotion = PromotionModel.fromFirestore(doc);
      
      // Update with incremented usage
      PromotionModel updatedPromotion = promotion.incrementUsage();
      await updatePromotion(updatedPromotion);
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing promotion usage: $e');
      }
      throw Exception('Failed to increment promotion usage: $e');
    }
  }
  
  // Get applicable promotions for a menu item
  Future<List<PromotionModel>> getApplicablePromotionsForMenuItem(
    String vendorId, 
    String menuItemId
  ) async {
    try {
      List<PromotionModel> activePromotions = await getActiveVendorPromotions(vendorId);
      
      return activePromotions.where((promotion) => 
          promotion.isApplicableToMenuItem(menuItemId)
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting applicable promotions: $e');
      }
      throw Exception('Failed to get applicable promotions: $e');
    }
  }
  
  // Calculate best discount for a menu item
  Future<double> calculateBestDiscount(
    String vendorId, 
    String menuItemId, 
    double originalPrice
  ) async {
    try {
      List<PromotionModel> applicablePromotions = 
          await getApplicablePromotionsForMenuItem(vendorId, menuItemId);
      
      if (applicablePromotions.isEmpty) {
        return 0.0;
      }
      
      // Calculate discount for each promotion and find the best one
      double bestDiscount = 0.0;
      
      for (var promotion in applicablePromotions) {
        double discount = promotion.calculateDiscount(originalPrice);
        if (discount > bestDiscount) {
          bestDiscount = discount;
        }
      }
      
      return bestDiscount;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating best discount: $e');
      }
      throw Exception('Failed to calculate best discount: $e');
    }
  }
  
  // Stream of promotions for a vendor
  Stream<List<PromotionModel>> vendorPromotionsStream(String vendorId) {
    return _promotionsCollection
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => PromotionModel.fromFirestore(doc)).toList());
  }
  
  // Calculate promotion discount
  Future<double> calculatePromotionDiscount(String promotionId, double orderTotal) async {
    try {
      PromotionModel promotion = await getPromotionById(promotionId);
      
      if (!promotion.isActive) {
        return 0.0;
      }
      
      // Check if promotion is valid
      DateTime now = DateTime.now();
      if (now.isBefore(promotion.startDate) || now.isAfter(promotion.endDate)) {
        return 0.0;
      }
      
      // Check usage limit
      if (promotion.usageLimit != null && promotion.usageCount >= promotion.usageLimit!) {
        return 0.0;
      }
      
      // Check minimum order value
      if (orderTotal < promotion.minimumOrderValue) {
        return 0.0;
      }
      
      // Calculate discount
      double discount = 0.0;
      if (promotion.discountType == DiscountType.percentage) {
        discount = orderTotal * (promotion.discountValue / 100);
        // Cap at maximum discount if specified
        if (promotion.maximumDiscount != null && discount > promotion.maximumDiscount!) {
          discount = promotion.maximumDiscount!;
        }
      } else {
        // Fixed amount discount
        discount = promotion.discountValue;
      }
      
      return discount;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating promotion discount: $e');
      }
      return 0.0;
    }
  }
}