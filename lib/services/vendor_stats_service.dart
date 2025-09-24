import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'review_service.dart';

class VendorStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReviewService _reviewService = ReviewService();

  // Get vendor dashboard statistics
  Future<Map<String, dynamic>> getVendorDashboardStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final vendorId = user.uid;

      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get all orders for this vendor (simplified query to avoid index issues)
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendor_id', isEqualTo: vendorId)
          .get();

      // Get menu items count
      final menuSnapshot = await _firestore
          .collection('menu_items')
          .where('vendor_id', isEqualTo: vendorId)
          .get();

      // Calculate statistics
      final allOrders = ordersSnapshot.docs;

      // Total orders
      final totalOrders = allOrders.length;

      // Today's revenue - filter in memory to avoid composite index
      double todayRevenue = 0.0;
      for (var doc in allOrders) {
        final data = doc.data();
        final orderTime = data['order_time'] as Timestamp?;
        final amount = (data['total_amount'] ?? 0.0).toDouble();
        final status = data['status'] ?? '';
        
        // Check if order is from today and completed
        if (orderTime != null) {
          final orderDate = orderTime.toDate();
          if (orderDate.isAfter(todayStart) && 
              orderDate.isBefore(todayEnd) && 
              status == 'completed') {
            todayRevenue += amount;
          }
        }
      }

      // Menu items count
      final menuItemsCount = menuSnapshot.docs.length;

      // Get actual vendor rating from review service
      double averageRating = 0.0;
      int totalReviews = 0;
      try {
        final ratingSummary = await _reviewService.getVendorRatingSummary(vendorId);
        averageRating = ratingSummary.averageRating;
        totalReviews = ratingSummary.totalReviews;
      } catch (e) {
        if (kDebugMode) {
          print('Error getting vendor rating: $e');
        }
        averageRating = 0.0; // Default to 0 if no reviews
      }

      // Get vendor wallet balance
      final vendorDoc = await _firestore.collection('vendors').doc(vendorId).get();
      final walletBalance = vendorDoc.exists 
          ? (vendorDoc.data()?['wallet_balance'] ?? 0.0).toDouble()
          : 0.0;

      // Get pending orders count - filter in memory
      int pendingOrdersCount = 0;
      for (var doc in allOrders) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status == 'placed') {
          pendingOrdersCount++;
        }
      }

      return {
        'total_orders': totalOrders,
        'today_revenue': todayRevenue,
        'menu_items': menuItemsCount,
        'rating': averageRating,
        'total_reviews': totalReviews,
        'wallet_balance': walletBalance,
        'pending_orders': pendingOrdersCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor dashboard stats: $e');
      }
      // Return default values in case of error
      return {
        'total_orders': 0,
        'today_revenue': 0.0,
        'menu_items': 0,
        'rating': 0.0,
        'total_reviews': 0,
        'wallet_balance': 0.0,
        'pending_orders': 0,
      };
    }
  }

  // Get vendor performance metrics
  Future<Map<String, dynamic>> getVendorPerformanceMetrics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final vendorId = user.uid;

      // Get all orders for this vendor (simplified query to avoid index issues)
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendor_id', isEqualTo: vendorId)
          .get();

      final orders = ordersSnapshot.docs;
      
      // Calculate metrics - filter in memory to avoid composite index
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      int totalOrders = 0;
      int completedOrders = 0;
      int rejectedOrders = 0;
      double totalRevenue = 0.0;
      double averageOrderValue = 0.0;

      for (var doc in orders) {
        final data = doc.data();
        final orderTime = data['order_time'] as Timestamp?;
        final status = data['status'] ?? '';
        final amount = (data['total_amount'] ?? 0.0).toDouble();

        // Check if order is from last 30 days
        if (orderTime != null) {
          final orderDate = orderTime.toDate();
          if (orderDate.isAfter(thirtyDaysAgo)) {
            totalOrders++;
            
            if (status == 'completed') {
              completedOrders++;
              totalRevenue += amount;
            } else if (status == 'rejected') {
              rejectedOrders++;
            }
          }
        }
      }

      averageOrderValue = completedOrders > 0 ? totalRevenue / completedOrders : 0.0;
      double completionRate = totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;

      return {
        'total_orders_30_days': totalOrders,
        'completed_orders': completedOrders,
        'rejected_orders': rejectedOrders,
        'total_revenue_30_days': totalRevenue,
        'average_order_value': averageOrderValue,
        'completion_rate': completionRate,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor performance metrics: $e');
      }
      return {
        'total_orders_30_days': 0,
        'completed_orders': 0,
        'rejected_orders': 0,
        'total_revenue_30_days': 0.0,
        'average_order_value': 0.0,
        'completion_rate': 0.0,
      };
    }
  }
}
