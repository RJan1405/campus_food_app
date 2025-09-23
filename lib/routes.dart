import 'package:flutter/material.dart';
import 'package:campus_food_app/screens/admin/dashboard_screen.dart';
import 'package:campus_food_app/screens/admin/vendor_management_screen.dart';
import 'package:campus_food_app/screens/admin/pickup_slot_management_screen.dart';
import 'package:campus_food_app/screens/admin/analytics_screen.dart';
import 'package:campus_food_app/screens/auth/login_screen.dart';
import 'package:campus_food_app/screens/student/home_screen.dart';
import 'package:campus_food_app/screens/student/profile_screen.dart';
import 'package:campus_food_app/screens/student/order_history_screen.dart';
import 'package:campus_food_app/screens/student/notification_screen.dart';
import 'package:campus_food_app/screens/vendor/dashboard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String studentHome = '/student/home';
  static const String studentProfile = '/student/profile';
  static const String studentOrders = '/student/orders';
  static const String studentNotifications = '/student/notifications';
  static const String vendorDashboard = '/vendor/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminVendors = '/admin/vendors';
  static const String adminPickupSlots = '/admin/pickup-slots';
  static const String adminAnalytics = '/admin/analytics';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      studentHome: (context) => const HomeScreen(),
      studentProfile: (context) => const ProfileScreen(),
      studentOrders: (context) => const OrderHistoryScreen(),
      studentNotifications: (context) => const NotificationScreen(),
      vendorDashboard: (context) => const DashboardScreen(),
      adminDashboard: (context) => const AdminDashboardScreen(),
      adminVendors: (context) => const VendorManagementScreen(),
      adminPickupSlots: (context) => const PickupSlotManagementScreen(),
      adminAnalytics: (context) => const AnalyticsScreen(),
    };
  }
}