import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/wallet_transaction_model.dart';
import 'wallet_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();
  
  // Collection references
  final CollectionReference _ordersCollection = 
      FirebaseFirestore.instance.collection('orders');
  
  // Create a new order from cart
  Future<String> placeOrder({
    required CartModel cart,
    required String userId,
    required String pickupSlotId,
    String? specialInstructions,
  }) async {
    try {
      // Validate cart is not empty
      if (cart.isEmpty) {
        throw Exception('Cannot place order with empty cart');
      }
      
      // Create order items from cart items
      List<OrderItemModel> orderItems = cart.items.map((cartItem) => 
        OrderItemModel(
          menuItemId: cartItem.menuItemId,
          name: cartItem.name,
          quantity: cartItem.quantity,
          price: cartItem.price,
          discountedPrice: cartItem.discountedPrice,
        )
      ).toList();
      
      // Create new order
      final newOrder = {
        'user_id': userId,
        'vendor_id': cart.vendorId,
        'items': orderItems.map((item) => item.toMap()).toList(),
        'subtotal': cart.subtotal,
        'discount': cart.discount,
        'total': cart.total,
        'status': OrderStatus.placed.toString().split('.').last,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'pickup_slot_id': pickupSlotId,
        'special_instructions': specialInstructions,
      };
      
      // Add order to Firestore
      DocumentReference orderRef = await _ordersCollection.add(newOrder);
      
      // Process payment from wallet
      await _walletService.processPayment(
        userId: userId,
        amount: cart.total,
        orderId: orderRef.id,
      );
      
      return orderRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error placing order: $e');
      }
      throw Exception('Failed to place order: $e');
    }
  }
  
  // Get order by ID
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _ordersCollection.doc(orderId).get();
      
      if (!doc.exists) {
        throw Exception('Order not found');
      }
      
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting order: $e');
      }
      throw Exception('Failed to get order: $e');
    }
  }
  
  // Get orders for a user
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _ordersCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user orders: $e');
      }
      throw Exception('Failed to get user orders: $e');
    }
  }
  
  // Get orders for a vendor
  Future<List<OrderModel>> getVendorOrders(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _ordersCollection
          .where('vendor_id', isEqualTo: vendorId)
          .orderBy('created_at', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor orders: $e');
      }
      throw Exception('Failed to get vendor orders: $e');
    }
  }
  
  // Get active orders for a vendor (not completed or cancelled)
  Future<List<OrderModel>> getActiveVendorOrders(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _ordersCollection
          .where('vendor_id', isEqualTo: vendorId)
          .where('status', whereNotIn: [
            OrderStatus.completed.toString().split('.').last,
            OrderStatus.cancelled.toString().split('.').last,
            OrderStatus.rejected.toString().split('.').last,
          ])
          .orderBy('created_at')
          .get();
      
      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active vendor orders: $e');
      }
      throw Exception('Failed to get active vendor orders: $e');
    }
  }
  
  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': newStatus.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      throw Exception('Failed to update order status: $e');
    }
  }
  
  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      // Get the order first to check if it can be cancelled
      DocumentSnapshot orderDoc = await _ordersCollection.doc(orderId).get();
      
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      Map<String, dynamic> data = orderDoc.data() as Map<String, dynamic>;
      String status = data['status'] ?? '';
      
      // Only allow cancellation if order is placed or accepted
      if (status != OrderStatus.placed.toString().split('.').last && 
          status != OrderStatus.accepted.toString().split('.').last) {
        throw Exception('Cannot cancel order in ${status} status');
      }
      
      // Update order status to cancelled
      await _ordersCollection.doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Process refund
      String userId = data['user_id'];
      double total = (data['total'] ?? 0.0).toDouble();
      
      await _walletService.processRefund(
        userId: userId,
        amount: total,
        orderId: orderId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling order: $e');
      }
      throw Exception('Failed to cancel order: $e');
    }
  }
  
  // Stream of order updates for a specific order
  Stream<OrderModel> orderStream(String orderId) {
    return _ordersCollection
        .doc(orderId)
        .snapshots()
        .map((doc) => OrderModel.fromFirestore(doc));
  }
  
  // Stream of active orders for a user
  Stream<List<OrderModel>> userActiveOrdersStream(String userId) {
    return _ordersCollection
        .where('user_id', isEqualTo: userId)
        .where('status', whereNotIn: [
          OrderStatus.completed.toString().split('.').last,
          OrderStatus.cancelled.toString().split('.').last,
          OrderStatus.rejected.toString().split('.').last,
        ])
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }
}