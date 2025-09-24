import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderPlaced,
  orderAccepted,
  orderPreparing,
  orderReady,
  orderCompleted,
  orderCancelled,
  orderRejected,
  paymentReceived,
  paymentRefunded,
  reviewReceived,
  general,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class NotificationModel {
  final String id;
  final String userId;
  final String? vendorId;
  final String? orderId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime timestamp;
  final NotificationPriority priority;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    this.vendorId,
    this.orderId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.timestamp,
    this.priority = NotificationPriority.medium,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      vendorId: data['vendor_id'],
      orderId: data['order_id'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.general,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['is_read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      data: data['data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'vendor_id': vendorId,
      'order_id': orderId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'is_read': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'priority': priority.toString().split('.').last,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? vendorId,
    String? orderId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? timestamp,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorId: vendorId ?? this.vendorId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      data: data ?? this.data,
    );
  }
}