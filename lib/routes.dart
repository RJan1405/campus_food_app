import 'package:flutter/material.dart';
import 'package:campus_food_app/screens/admin/admin_dashboard_screen.dart';
import 'package:campus_food_app/screens/admin/vendor_approval_management_screen.dart';
import 'package:campus_food_app/screens/admin/user_management_screen.dart';
import 'package:campus_food_app/screens/admin/super_admin_setup_screen.dart';
import 'package:campus_food_app/screens/vendor/vendor_approval_screen.dart';
import 'package:campus_food_app/screens/vendor/vendor_status_screen.dart';
import 'package:campus_food_app/screens/auth/login_screen.dart';
import 'package:campus_food_app/screens/student/home_screen.dart';
import 'package:campus_food_app/screens/student/profile_screen.dart';
import 'package:campus_food_app/screens/student/order_history_screen.dart';
import 'package:campus_food_app/screens/student/notifications_screen.dart';
import 'package:campus_food_app/screens/student/cart_screen.dart';
import 'package:campus_food_app/screens/student/payment_screen.dart';
import 'package:campus_food_app/screens/student/wallet_screen.dart';
import 'package:campus_food_app/screens/vendor/dashboard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String studentHome = '/student/home';
  static const String studentProfile = '/student/profile';
  static const String studentOrders = '/student/orders';
  static const String studentNotifications = '/student/notifications';
  static const String studentCart = '/student/cart';
  static const String studentPayment = '/student/payment';
  static const String studentWallet = '/student/wallet';
  static const String vendorDashboard = '/vendor/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminVendorApprovals = '/admin/vendor-approvals';
  static const String adminUserManagement = '/admin/user-management';
  static const String superAdminSetup = '/admin/super-admin-setup';
  static const String vendorApproval = '/vendor/approval';
  static const String vendorStatus = '/vendor/status';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      studentHome: (context) => const HomeScreen(),
      studentProfile: (context) => const ProfileScreen(),
      studentOrders: (context) => const OrderHistoryScreen(),
      studentNotifications: (context) => const NotificationsScreen(),
      studentCart: (context) => const CartScreen(),
    studentPayment: (context) => const PaymentScreen(),
    studentWallet: (context) => const WalletScreen(),
      vendorDashboard: (context) => const DashboardScreen(),
      adminDashboard: (context) => const AdminDashboardScreen(),
      adminVendorApprovals: (context) => const VendorApprovalManagementScreen(),
      adminUserManagement: (context) => const UserManagementScreen(),
      superAdminSetup: (context) => const SuperAdminSetupScreen(),
      vendorApproval: (context) => const VendorApprovalScreen(),
      vendorStatus: (context) => const VendorStatusScreen(),
    };
  }
}