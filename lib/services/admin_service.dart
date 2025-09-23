import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';
import '../models/vendor_model.dart';

class AdminService {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _adminsCollection = 
      FirebaseFirestore.instance.collection('admins');
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _vendorsCollection = 
      FirebaseFirestore.instance.collection('vendors');
  final CollectionReference _ordersCollection = 
      FirebaseFirestore.instance.collection('orders');
  final CollectionReference _walletTransactionsCollection = 
      FirebaseFirestore.instance.collection('wallet_transactions');
  
  // Check if user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _adminsCollection
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user is admin: $e');
      }
      throw Exception('Failed to check if user is admin: $e');
    }
  }
  
  // Get admin by user ID
  Future<AdminModel?> getAdminByUserId(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _adminsCollection
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return AdminModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting admin by user ID: $e');
      }
      throw Exception('Failed to get admin by user ID: $e');
    }
  }
  
  // Create a new admin
  Future<String> createAdmin(AdminModel admin) async {
    try {
      DocumentReference docRef = await _adminsCollection.add(admin.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin: $e');
      }
      throw Exception('Failed to create admin: $e');
    }
  }
  
  // Update admin
  Future<void> updateAdmin(AdminModel admin) async {
    try {
      await _adminsCollection.doc(admin.id).update(admin.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin: $e');
      }
      throw Exception('Failed to update admin: $e');
    }
  }
  
  // Update admin last login
  Future<void> updateAdminLastLogin(String adminId) async {
    try {
      DocumentSnapshot doc = await _adminsCollection.doc(adminId).get();
      
      if (!doc.exists) {
        throw Exception('Admin not found');
      }
      
      AdminModel admin = AdminModel.fromFirestore(doc);
      AdminModel updatedAdmin = admin.updateLastLogin();
      
      await updateAdmin(updatedAdmin);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin last login: $e');
      }
      throw Exception('Failed to update admin last login: $e');
    }
  }
  
  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _usersCollection.get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      throw Exception('Failed to get all users: $e');
    }
  }
  
  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      QuerySnapshot querySnapshot = await _usersCollection
          .where('role', isEqualTo: role)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users by role: $e');
      }
      throw Exception('Failed to get users by role: $e');
    }
  }
  
  // Get pending vendor approvals
  Future<List<VendorModel>> getPendingVendorApprovals() async {
    try {
      // This assumes there's a 'status' field in the vendor model
      // You might need to adjust based on your actual implementation
      QuerySnapshot querySnapshot = await _vendorsCollection
          .where('status', isEqualTo: 'pending')
          .get();
      
      return querySnapshot.docs
          .map((doc) => VendorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending vendor approvals: $e');
      }
      throw Exception('Failed to get pending vendor approvals: $e');
    }
  }
  
  // Approve vendor
  Future<void> approveVendor(String vendorId) async {
    try {
      await _vendorsCollection.doc(vendorId).update({
        'status': 'approved',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error approving vendor: $e');
      }
      throw Exception('Failed to approve vendor: $e');
    }
  }
  
  // Reject vendor
  Future<void> rejectVendor(String vendorId) async {
    try {
      await _vendorsCollection.doc(vendorId).update({
        'status': 'rejected',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting vendor: $e');
      }
      throw Exception('Failed to reject vendor: $e');
    }
  }
  
  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics() async {
    try {
      QuerySnapshot querySnapshot = await _walletTransactionsCollection.get();
      
      double totalTransactions = 0;
      double totalTopups = 0;
      double totalPayments = 0;
      double totalRefunds = 0;
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = (data['amount'] ?? 0.0).toDouble();
        String type = data['type'] ?? '';
        
        totalTransactions += amount;
        
        if (type == 'topup') {
          totalTopups += amount;
        } else if (type == 'payment') {
          totalPayments += amount;
        } else if (type == 'refund') {
          totalRefunds += amount;
        }
      }
      
      return {
        'total_transactions': totalTransactions,
        'total_topups': totalTopups,
        'total_payments': totalPayments,
        'total_refunds': totalRefunds,
        'transaction_count': querySnapshot.docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting transaction statistics: $e');
      }
      throw Exception('Failed to get transaction statistics: $e');
    }
  }
  
  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      QuerySnapshot querySnapshot = await _ordersCollection.get();
      
      int totalOrders = querySnapshot.docs.length;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalSales = 0;
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? '';
        double total = (data['total'] ?? 0.0).toDouble();
        
        if (status == 'completed') {
          completedOrders++;
          totalSales += total;
        } else if (status == 'cancelled' || status == 'rejected') {
          cancelledOrders++;
        }
      }
      
      return {
        'total_orders': totalOrders,
        'completed_orders': completedOrders,
        'cancelled_orders': cancelledOrders,
        'total_sales': totalSales,
        'completion_rate': totalOrders > 0 ? completedOrders / totalOrders : 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting order statistics: $e');
      }
      throw Exception('Failed to get order statistics: $e');
    }
  }
  
  // Get vendor statistics
  Future<Map<String, dynamic>> getVendorStatistics() async {
    try {
      QuerySnapshot vendorSnapshot = await _vendorsCollection.get();
      
      int totalVendors = vendorSnapshot.docs.length;
      int activeVendors = 0;
      
      for (var doc in vendorSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isOpen = data['is_open'] ?? false;
        
        if (isOpen) {
          activeVendors++;
        }
      }
      
      return {
        'total_vendors': totalVendors,
        'active_vendors': activeVendors,
        'inactive_vendors': totalVendors - activeVendors,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor statistics: $e');
      }
      throw Exception('Failed to get vendor statistics: $e');
    }
  }
  
  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      QuerySnapshot userSnapshot = await _usersCollection.get();
      
      int totalUsers = userSnapshot.docs.length;
      int students = 0;
      int staff = 0;
      int vendors = 0;
      
      for (var doc in userSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? '';
        
        if (role == 'student') {
          students++;
        } else if (role == 'staff') {
          staff++;
        } else if (role == 'vendor') {
          vendors++;
        }
      }
      
      return {
        'total_users': totalUsers,
        'students': students,
        'staff': staff,
        'vendors': vendors,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user statistics: $e');
      }
      throw Exception('Failed to get user statistics: $e');
    }
  }
  
  // Get dashboard statistics (combined)
  Future<Map<String, dynamic>> getDashboardStatistics() async {
    try {
      Map<String, dynamic> transactionStats = await getTransactionStatistics();
      Map<String, dynamic> orderStats = await getOrderStatistics();
      Map<String, dynamic> vendorStats = await getVendorStatistics();
      Map<String, dynamic> userStats = await getUserStatistics();
      
      return {
        'transactions': transactionStats,
        'orders': orderStats,
        'vendors': vendorStats,
        'users': userStats,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting dashboard statistics: $e');
      }
      throw Exception('Failed to get dashboard statistics: $e');
    }
  }
}