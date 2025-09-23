import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _notificationsCollection = 
      FirebaseFirestore.instance.collection('notifications');
  
  // Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize Flutter Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS = 
          DarwinInitializationSettings();
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
      }
    }
  }
  
  // Send notification to a user
  Future<String> sendNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? actionData,
    String? imageUrl,
  }) async {
    try {
      // Create notification in Firestore
      NotificationModel notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        actionData: actionData,
        imageUrl: imageUrl,
      );
      
      DocumentReference docRef = await _notificationsCollection.add(notification.toMap());
      
      // Show local notification
      await _showLocalNotification(title, message);
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      throw Exception('Failed to send notification: $e');
    }
  }
  
  // Show local notification
  Future<void> _showLocalNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'campus_food_app_channel',
        'Campus Food App Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification: $e');
      }
    }
  }
  
  // Send order status notification
  Future<String> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String vendorName,
    required OrderStatus status,
  }) async {
    String title;
    String message;
    
    switch (status) {
      case OrderStatus.accepted:
        title = 'Order Accepted';
        message = '$vendorName has accepted your order';
        break;
      case OrderStatus.preparing:
        title = 'Order Being Prepared';
        message = '$vendorName is preparing your order';
        break;
      case OrderStatus.ready:
        title = 'Order Ready for Pickup';
        message = 'Your order from $vendorName is ready for pickup';
        break;
      case OrderStatus.completed:
        title = 'Order Completed';
        message = 'Your order from $vendorName has been completed';
        break;
      case OrderStatus.cancelled:
        title = 'Order Cancelled';
        message = 'Your order from $vendorName has been cancelled';
        break;
      case OrderStatus.rejected:
        title = 'Order Rejected';
        message = '$vendorName could not accept your order';
        break;
      default:
        title = 'Order Update';
        message = 'There is an update to your order from $vendorName';
    }
    
    return sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.orderUpdate,
      actionData: orderId,
    );
  }
  
  // Send wallet alert notification
  Future<String> sendWalletAlertNotification({
    required String userId,
    required double balance,
    required bool isLowBalance,
  }) async {
    String title;
    String message;
    
    if (isLowBalance) {
      title = 'Low Wallet Balance';
      message = 'Your wallet balance is low (₹$balance). Please top up to continue ordering.';
    } else {
      title = 'Wallet Updated';
      message = 'Your wallet has been updated. Current balance: ₹$balance';
    }
    
    return sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.walletAlert,
    );
  }
  
  // Send promotional notification
  Future<String> sendPromotionalNotification({
    required String userId,
    required String vendorId,
    required String vendorName,
    required String promotionTitle,
    String? imageUrl,
  }) async {
    return sendNotification(
      userId: userId,
      title: 'New Offer from $vendorName',
      message: promotionTitle,
      type: NotificationType.promotion,
      actionData: vendorId,
      imageUrl: imageUrl,
    );
  }
  
  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _notificationsCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user notifications: $e');
      }
      throw Exception('Failed to get user notifications: $e');
    }
  }
  
  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'is_read': true,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
      throw Exception('Failed to mark notification as read: $e');
    }
  }
  
  // Mark all user notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _notificationsCollection
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();
      
      WriteBatch batch = _firestore.batch();
      
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      throw Exception('Failed to delete notification: $e');
    }
  }
  
  // Stream of user notifications - renamed to match what's being called in the provider
  // Stream of user notifications - renamed to match what's being called in the provider
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _notificationsCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }
  
  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _notificationsCollection
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread notification count: $e');
      }
      throw Exception('Failed to get unread notification count: $e');
    }
  }
}