import 'package:flutter/foundation.dart';
import 'package:campus_food_app/models/notification_model.dart';
import 'package:campus_food_app/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> fetchUserNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get the first snapshot from the stream
      final stream = _notificationService.getUserNotifications(userId);
      _notifications = await stream.first;
      _calculateUnreadCount();
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _calculateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      
      // Update all local notifications
      _notifications = _notifications.map((notification) => 
        notification.isRead ? notification : notification.copyWith(isRead: true)
      ).toList();
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((notification) => !notification.isRead).length;
  }

  // Listen to real-time notifications
  void startListeningToNotifications(String userId) {
    _notificationService.getUserNotifications(userId).listen((notifications) {
      _notifications = notifications;
      _calculateUnreadCount();
      notifyListeners();
    });
  }
}