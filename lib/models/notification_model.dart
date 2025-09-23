import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderUpdate,
  promotion,
  walletAlert,
  adminMessage
}

class NotificationModel {
  final String id;
  final String userId; // Recipient user ID
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionData; // e.g., order ID, vendor ID for deep linking
  final String? imageUrl; // Optional image for rich notifications
  
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.actionData,
    this.imageUrl,
  });
  
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type'] ?? 'orderUpdate'}',
        orElse: () => NotificationType.orderUpdate,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['is_read'] ?? false,
      actionData: data['action_data'],
      imageUrl: data['image_url'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_read': isRead,
      'action_data': actionData,
      'image_url': imageUrl,
    };
  }
  
  // Mark notification as read
  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: true,
      actionData: actionData,
      imageUrl: imageUrl,
    );
  }
}