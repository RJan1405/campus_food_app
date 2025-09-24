import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send notification to a specific user
  Future<void> sendNotification({
    required String userId,
    String? vendorId,
    String? orderId,
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Firestore will generate this
        userId: userId,
        vendorId: vendorId,
        orderId: orderId,
        type: type,
        title: title,
        message: message,
        priority: priority,
        data: data,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());
      
      if (kDebugMode) {
        print('Notification sent to user $userId: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      rethrow;
    }
  }

  // Send notification to multiple users
  Future<void> sendNotificationToMultiple({
    required List<String> userIds,
    String? vendorId,
    String? orderId,
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (final userId in userIds) {
        final notification = NotificationModel(
          id: '', // Firestore will generate this
          userId: userId,
          vendorId: vendorId,
          orderId: orderId,
          type: type,
          title: title,
          message: message,
          priority: priority,
          data: data,
          timestamp: DateTime.now(),
        );

        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification.toMap());
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('Notifications sent to ${userIds.length} users: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notifications to multiple users: $e');
      }
      rethrow;
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
      rethrow;
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      rethrow;
    }
  }

  // Clear old notifications (older than 30 days)
  Future<void> clearOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      if (kDebugMode) {
        print('Cleared ${oldNotifications.docs.length} old notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing old notifications: $e');
      }
      rethrow;
    }
  }

  // Order-specific notification methods
  Future<void> notifyOrderPlaced(String userId, String orderId, String vendorName) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.orderPlaced,
      title: 'Order Placed Successfully',
      message: 'Your order has been placed at $vendorName and is being processed.',
      priority: NotificationPriority.medium,
    );
  }

  Future<void> notifyOrderAccepted(String userId, String orderId, String vendorName) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.orderAccepted,
      title: 'Order Accepted',
      message: 'Your order at $vendorName has been accepted and is being prepared.',
      priority: NotificationPriority.high,
    );
  }

  Future<void> notifyOrderPreparing(String userId, String orderId, String vendorName) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.orderPreparing,
      title: 'Food is Being Prepared',
      message: 'Your order at $vendorName is being prepared. It will be ready soon!',
      priority: NotificationPriority.medium,
    );
  }

  Future<void> notifyOrderReady(String userId, String orderId, String vendorName) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.orderReady,
      title: 'Order Ready for Pickup',
      message: 'Your order at $vendorName is ready for pickup!',
      priority: NotificationPriority.high,
    );
  }

  Future<void> notifyOrderCompleted(String userId, String orderId, String vendorName) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.orderCompleted,
      title: 'Order Completed',
      message: 'Your order at $vendorName has been completed. Thank you!',
      priority: NotificationPriority.medium,
    );
  }

  Future<void> notifyOrderCancelled(String userId, String orderId, String vendorName, String reason) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.orderCancelled,
      title: 'Order Cancelled',
      message: 'Your order at $vendorName has been cancelled. Reason: $reason',
      priority: NotificationPriority.high,
    );
  }

  Future<void> notifyOrderRejected(String userId, String orderId, String vendorName, String reason) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.orderRejected,
      title: 'Order Rejected',
      message: 'Your order at $vendorName has been rejected. Reason: $reason',
      priority: NotificationPriority.high,
    );
  }

  Future<void> notifyPaymentReceived(String vendorId, String orderId, double amount) async {
    await sendNotification(
      userId: vendorId,
      orderId: orderId,
      type: NotificationType.paymentReceived,
      title: 'Payment Received',
      message: 'You have received ₹${amount.toStringAsFixed(2)} for order #${orderId.substring(0, 8)}',
      priority: NotificationPriority.high,
    );
  }

  Future<void> notifyPaymentRefunded(String userId, String orderId, double amount) async {
    await sendNotification(
      userId: userId,
      orderId: orderId,
      type: NotificationType.paymentRefunded,
      title: 'Payment Refunded',
      message: '₹${amount.toStringAsFixed(2)} has been refunded to your wallet for order #${orderId.substring(0, 8)}',
      priority: NotificationPriority.high,
    );
  }

  Future<void> notifyReviewReceived(String vendorId, String reviewerName, double rating) async {
    await sendNotification(
      userId: vendorId,
      type: NotificationType.reviewReceived,
      title: 'New Review Received',
      message: '$reviewerName rated you $rating stars!',
      priority: NotificationPriority.medium,
    );
  }
}