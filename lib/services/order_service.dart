import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/transaction_model.dart';
import 'wallet_service.dart';
import 'vendor_wallet_service.dart';
import 'transaction_service.dart';
import 'notification_service.dart';

class OrderService {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();
  final VendorWalletService _vendorWalletService = VendorWalletService();
  final TransactionService _transactionService = TransactionService();
  final NotificationService _notificationService = NotificationService();
  
  // Collection references
  final CollectionReference _ordersCollection = 
      FirebaseFirestore.instance.collection('orders');
  
  // Create a new order with individual parameters
  Future<OrderModel?> placeOrder({
    required String userId,
    required String vendorId,
    required String vendorName,
    required List<OrderItemModel> items,
    required double totalAmount,
    required double discountedAmount,
    required double walletSavings,
    String? note,
    DateTime? pickupTime,
    String? promotionId,
  }) async {
    try {
      // Create new order
      final newOrder = {
        'user_id': userId,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'items': items.map((item) => item.toMap()).toList(),
        'total_amount': totalAmount,
        'discounted_amount': discountedAmount,
        'wallet_savings': walletSavings,
        'status': OrderStatus.placed.toString().split('.').last,
        'order_time': FieldValue.serverTimestamp(),
        'pickup_time': pickupTime != null ? Timestamp.fromDate(pickupTime) : null,
        'note': note,
        'promotion_id': promotionId,
      };
      
      // Add order to Firestore
      DocumentReference orderRef = await _ordersCollection.add(newOrder);
      
      // Get the created order
      DocumentSnapshot orderDoc = await orderRef.get();
      return OrderModel.fromFirestore(orderDoc);
    } catch (e) {
      if (kDebugMode) {
        print('Error placing order: $e');
      }
      return null;
    }
  }

  // Create a new order from cart (handles multiple vendors)
  Future<String> placeOrderFromCart({
    required CartModel cart,
    required String userId,
    required String pickupSlotId,
    String? specialInstructions,
    String? paymentMethod,
    String? paymentId,
  }) async {
    try {
      // Validate cart is not empty
      if (cart.isEmpty) {
        throw Exception('Cannot place order with empty cart');
      }
      
      // For multi-vendor carts, we'll create separate orders for each vendor
      // For now, we'll return the first order ID (you might want to handle this differently)
      String? firstOrderId;
      
      for (String vendorId in cart.vendorIds) {
        List<dynamic> vendorItems = cart.getItemsForVendor(vendorId);
        
        // Create order items from cart items for this vendor
        List<OrderItemModel> orderItems = vendorItems.map((cartItem) => 
          OrderItemModel(
            menuItemId: cartItem.menuItemId,
            name: cartItem.name,
            quantity: cartItem.quantity,
            price: cartItem.price,
            discountedPrice: cartItem.discountedPrice,
          )
        ).toList();
        
        // Calculate totals for this vendor
        double vendorTotal = vendorItems.fold(0.0, (sum, item) => sum + (item.discountedPrice * item.quantity));
        double vendorDiscount = vendorItems.fold(0.0, (sum, item) => sum + ((item.price - item.discountedPrice) * item.quantity));
        
        // Get vendor name
        String vendorName = 'Unknown Vendor';
        try {
          final vendorDoc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .get();
          if (vendorDoc.exists) {
            vendorName = vendorDoc.data()?['name'] ?? 'Unknown Vendor';
          }
        } catch (e) {
          print('Error getting vendor name: $e');
        }
        
        // Create new order for this vendor
        final newOrder = {
          'user_id': userId,
          'vendor_id': vendorId,
          'vendor_name': vendorName,
          'items': orderItems.map((item) => item.toMap()).toList(),
          'total_amount': vendorTotal,
          'discounted_amount': vendorTotal - vendorDiscount,
          'wallet_savings': 0.0,
          'status': OrderStatus.placed.toString().split('.').last,
          'order_time': FieldValue.serverTimestamp(),
          'pickup_time': null,
          'note': specialInstructions,
          'promotion_id': null,
          'payment_method': paymentMethod ?? 'unknown',
          'payment_id': paymentId,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };
        
        // Add order to Firestore
        DocumentReference orderRef = await _ordersCollection.add(newOrder);
        
        if (firstOrderId == null) {
          firstOrderId = orderRef.id;
        }
        
        // Record order payment transaction
        await _transactionService.recordTransaction(
          userId: userId,
          orderId: orderRef.id,
          vendorId: vendorId,
          vendorName: vendorName,
          amount: -vendorTotal, // Negative for payment
          type: TransactionType.orderPayment,
          description: 'Order payment to $vendorName',
          paymentMethod: paymentMethod,
          paymentId: paymentId,
        );
        
        print('Order created successfully: ${orderRef.id} for vendor: $vendorName');
        
        // Send notification to user about order placement
        await _notificationService.notifyOrderPlaced(userId, orderRef.id, vendorName);
      }
      
      return firstOrderId ?? '';
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
          .get();
      
      List<OrderModel> orders = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      
      // Sort by order time in memory to avoid Firestore index requirements
      orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      
      return orders;
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
          .get();
      
      List<OrderModel> allOrders = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      
      // Filter active orders in memory to avoid complex Firestore queries
      return allOrders.where((order) => 
        order.status != OrderStatus.completed &&
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.rejected
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active vendor orders: $e');
      }
      throw Exception('Failed to get active vendor orders: $e');
    }
  }

  // Stream of all orders for a vendor
  Stream<List<OrderModel>> getVendorOrdersStream(String vendorId) {
    return _ordersCollection
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      List<OrderModel> orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      
      // Sort by order time in memory
      orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      
      return orders;
    });
  }

  // Stream of active orders for a vendor
  Stream<List<OrderModel>> getActiveVendorOrdersStream(String vendorId) {
    return _ordersCollection
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      List<OrderModel> allOrders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      
      // Filter active orders in memory
      List<OrderModel> activeOrders = allOrders.where((order) => 
        order.status != OrderStatus.completed &&
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.rejected
      ).toList();
      
      // Sort by order time
      activeOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      
      return activeOrders;
    });
  }
  
  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, {
    String? rejectionReason,
    String? pickupLocation,
    String? estimatedReadyTime,
  }) async {
    try {
      // Get the order first to handle payment/refund logic
      DocumentSnapshot orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      String vendorId = orderData['vendor_id'] ?? '';
      String userId = orderData['user_id'] ?? '';
      double totalAmount = (orderData['total_amount'] ?? 0.0).toDouble();
      String currentStatus = orderData['status'] ?? '';
      
      Map<String, dynamic> updateData = {
        'status': newStatus.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      // Add specific timestamp based on status
      switch (newStatus) {
        case OrderStatus.accepted:
          updateData['accepted_time'] = FieldValue.serverTimestamp();
          // Transfer payment to vendor when order is accepted
          if (currentStatus == 'placed') {
            await _vendorWalletService.processOrderPayment(
              vendorId: vendorId,
              amount: totalAmount,
              orderId: orderId,
              customerId: userId,
            );
            print('Payment transferred to vendor: ₹$totalAmount for order: $orderId');
          }
          break;
        case OrderStatus.preparing:
          updateData['preparing_time'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.ready:
          updateData['ready_time'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.completed:
          updateData['pickup_time'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.rejected:
          // Refund payment to user when order is rejected
          if (currentStatus == 'accepted' || currentStatus == 'placed') {
            // First, refund from vendor wallet
            await _vendorWalletService.processRefund(
              vendorId: vendorId,
              amount: totalAmount,
              orderId: orderId,
              customerId: userId,
            );
            
            // Then, refund to user wallet
            await _walletService.processRefund(
              userId: userId,
              amount: totalAmount,
              orderId: orderId,
            );
            
            // Record refund transaction
            await _transactionService.recordTransaction(
              userId: userId,
              orderId: orderId,
              vendorId: vendorId,
              amount: totalAmount,
              type: TransactionType.orderRefund,
              description: 'Order refund - Order rejected by vendor',
              paymentMethod: 'refund',
            );
            
            print('Payment refunded to user: ₹$totalAmount for order: $orderId');
          }
          break;
        case OrderStatus.cancelled:
          // Refund payment to user when order is cancelled
          if (currentStatus == 'accepted' || currentStatus == 'placed') {
            // First, refund from vendor wallet if order was accepted
            if (currentStatus == 'accepted') {
              await _vendorWalletService.processRefund(
                vendorId: vendorId,
                amount: totalAmount,
                orderId: orderId,
                customerId: userId,
              );
            }
            
            // Then, refund to user wallet
            await _walletService.processRefund(
              userId: userId,
              amount: totalAmount,
              orderId: orderId,
            );
            
            // Record cancellation transaction
            await _transactionService.recordTransaction(
              userId: userId,
              orderId: orderId,
              vendorId: vendorId,
              amount: totalAmount,
              type: TransactionType.orderCancellation,
              description: 'Order cancellation refund',
              paymentMethod: 'refund',
            );
            
            print('Payment refunded to user: ₹$totalAmount for cancelled order: $orderId');
          }
          break;
        default:
          break;
      }
      
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        updateData['rejection_reason'] = rejectionReason;
      }
      
      if (pickupLocation != null && pickupLocation.isNotEmpty) {
        updateData['pickup_location'] = pickupLocation;
      }
      
      if (estimatedReadyTime != null && estimatedReadyTime.isNotEmpty) {
        updateData['estimated_ready_time'] = estimatedReadyTime;
      }
      
      await _ordersCollection.doc(orderId).update(updateData);
      print('Order status updated to: ${newStatus.name} for order: $orderId');
      
      // Send notifications based on status change
      await _sendStatusChangeNotifications(orderId, newStatus, userId, vendorId, rejectionReason);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      throw Exception('Failed to update order status: $e');
    }
  }
  
  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
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
      String vendorId = data['vendor_id'];
      double totalAmount = (data['total_amount'] ?? 0.0).toDouble();
      
      // If order was accepted, refund from vendor wallet first
      if (status == OrderStatus.accepted.toString().split('.').last) {
        await _vendorWalletService.processRefund(
          vendorId: vendorId,
          amount: totalAmount,
          orderId: orderId,
          customerId: userId,
        );
      }
      
      // Refund to user wallet
      await _walletService.processRefund(
        userId: userId,
        amount: totalAmount,
        orderId: orderId,
      );
      
      print('Payment refunded to user: ₹$totalAmount for cancelled order: $orderId');
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling order: $e');
      }
      return false;
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

  // Send notifications based on order status changes
  Future<void> _sendStatusChangeNotifications(
    String orderId,
    OrderStatus newStatus,
    String userId,
    String vendorId,
    String? rejectionReason,
  ) async {
    try {
      // Get vendor name for notifications
      String vendorName = 'Unknown Vendor';
      try {
        final vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .get();
        if (vendorDoc.exists) {
          vendorName = vendorDoc.data()?['name'] ?? 'Unknown Vendor';
        }
      } catch (e) {
        print('Error getting vendor name for notification: $e');
      }

      // Send notifications based on status
      switch (newStatus) {
        case OrderStatus.accepted:
          await _notificationService.notifyOrderAccepted(userId, orderId, vendorName);
          break;
        case OrderStatus.preparing:
          await _notificationService.notifyOrderPreparing(userId, orderId, vendorName);
          break;
        case OrderStatus.ready:
          await _notificationService.notifyOrderReady(userId, orderId, vendorName);
          break;
        case OrderStatus.completed:
          await _notificationService.notifyOrderCompleted(userId, orderId, vendorName);
          break;
        case OrderStatus.cancelled:
          await _notificationService.notifyOrderCancelled(
            userId, 
            orderId, 
            vendorName, 
            rejectionReason ?? 'Order cancelled'
          );
          break;
        case OrderStatus.rejected:
          await _notificationService.notifyOrderRejected(
            userId, 
            orderId, 
            vendorName, 
            rejectionReason ?? 'Order rejected'
          );
          break;
        default:
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending status change notifications: $e');
      }
    }
  }
}