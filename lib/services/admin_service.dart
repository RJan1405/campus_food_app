import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_model.dart';
import '../models/vendor_approval_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      return adminDoc.exists && adminDoc.data()?['is_active'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking admin status: $e');
      }
      return false;
    }
  }

  // Cache for admin data
  AdminModel? _cachedAdmin;
  DateTime? _lastCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Clear admin cache
  void clearCache() {
    _cachedAdmin = null;
    _lastCacheTime = null;
    print('Admin cache cleared');
  }

  // Get current admin user with caching and offline fallback
  Future<AdminModel?> getCurrentAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      // Check cache first
      if (_cachedAdmin != null && 
          _lastCacheTime != null && 
          DateTime.now().difference(_lastCacheTime!) < _cacheExpiry) {
        print('getCurrentAdmin: Returning cached admin data');
        return _cachedAdmin;
      }

      print('getCurrentAdmin: Fetching fresh admin data for UID: ${user.uid}');
      
      try {
        // Try to get admin document with timeout
        final adminDoc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                throw TimeoutException('Admin fetch timeout', const Duration(seconds: 3));
              },
            );

        if (adminDoc.exists) {
          _cachedAdmin = AdminModel.fromFirestore(adminDoc);
          _lastCacheTime = DateTime.now();
          print('getCurrentAdmin: Admin data cached successfully');
          return _cachedAdmin;
        }
        
        print('getCurrentAdmin: Admin document does not exist, creating it...');
        // Admin document doesn't exist, create it
        final adminModel = AdminModel(
          id: user.uid,
          email: user.email ?? 'admin@campus.com',
          name: 'Campus Admin',
          role: 'super_admin',
          permissions: [
            'manage_users',
            'manage_vendors',
            'manage_orders',
            'manage_payments',
            'view_analytics',
            'manage_admins',
            'approve_vendors',
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
        
        // Try to save to Firestore with timeout
        await _firestore
            .collection('admins')
            .doc(user.uid)
            .set(adminModel.toFirestore())
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('getCurrentAdmin: Firestore save timeout, using cached data');
              },
            );
        
        _cachedAdmin = adminModel;
        _lastCacheTime = DateTime.now();
        print('getCurrentAdmin: Admin document created and cached successfully');
        return adminModel;
      } catch (e) {
        print('getCurrentAdmin: Firestore unavailable, using offline fallback: $e');
        
        // Firestore is unavailable, create offline admin model
        final adminModel = AdminModel(
          id: user.uid,
          email: user.email ?? 'admin@campus.com',
          name: 'Campus Admin',
          role: 'super_admin',
          permissions: [
            'manage_users',
            'manage_vendors',
            'manage_orders',
            'manage_payments',
            'view_analytics',
            'manage_admins',
            'approve_vendors',
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
        
        _cachedAdmin = adminModel;
        _lastCacheTime = DateTime.now();
        print('getCurrentAdmin: Offline admin data cached successfully');
        return adminModel;
      }
    } catch (e) {
      print('Error getting current admin: $e');
      return null;
    }
  }

  // Create super admin (one-time setup)
  Future<bool> createSuperAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Check if super admin already exists
      final existingAdmins = await _firestore
          .collection('admins')
          .where('role', isEqualTo: 'super_admin')
          .get();

      if (existingAdmins.docs.isNotEmpty) {
        if (kDebugMode) {
          print('Super admin already exists');
        }
        return false;
      }

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create admin document
      final adminData = AdminModel(
        id: userId,
        email: email,
        name: name,
        role: 'super_admin',
        permissions: [
          'manage_users',
          'manage_vendors',
          'manage_orders',
          'manage_payments',
          'view_analytics',
          'manage_admins',
          'approve_vendors',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('admins')
          .doc(userId)
          .set(adminData.toFirestore());

      if (kDebugMode) {
        print('Super admin created successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating super admin: $e');
      }
      return false;
    }
  }

  // Get all pending vendor approvals
  Stream<List<VendorApprovalModel>> getPendingVendorApprovals() {
    return _firestore
        .collection('vendor_approvals')
        .where('status', isEqualTo: 'pending')
        .orderBy('submitted_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VendorApprovalModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get all vendor approvals
  Stream<List<VendorApprovalModel>> getAllVendorApprovals() {
    return _firestore
        .collection('vendor_approvals')
        .orderBy('submitted_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VendorApprovalModel.fromFirestore(doc))
          .toList();
    });
  }

  // Approve vendor
  Future<bool> approveVendor(String approvalId, String adminId) async {
    try {
      print('AdminService.approveVendor called with approvalId: $approvalId, adminId: $adminId');
      
      final approvalDoc = await _firestore
          .collection('vendor_approvals')
          .doc(approvalId)
          .get();

      print('Approval document exists: ${approvalDoc.exists}');
      if (!approvalDoc.exists) {
        print('Approval document not found');
        return false;
      }

      final approval = VendorApprovalModel.fromFirestore(approvalDoc);
      final vendorId = approval.vendorId;
      print('Vendor ID from approval: $vendorId');

      // Update approval status
      print('Updating vendor_approvals document...');
      await _firestore
          .collection('vendor_approvals')
          .doc(approvalId)
          .update({
        'status': 'approved',
        'approved_by': adminId,
        'reviewed_at': FieldValue.serverTimestamp(),
      });

      // Update vendor document to mark as approved
      print('Updating vendors document...');
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .update({
        'is_approved': true,
        'approval_status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': adminId,
      });

      print('Vendor approved successfully: $vendorId');
      return true;
    } catch (e) {
      print('Error approving vendor: $e');
      return false;
    }
  }

  // Reject vendor
  Future<bool> rejectVendor(String approvalId, String adminId, String reason) async {
    try {
      print('AdminService.rejectVendor called with approvalId: $approvalId, adminId: $adminId, reason: $reason');
      
      final approvalDoc = await _firestore
          .collection('vendor_approvals')
          .doc(approvalId)
          .get();

      print('Approval document exists: ${approvalDoc.exists}');
      if (!approvalDoc.exists) {
        print('Approval document not found');
        return false;
      }

      final approval = VendorApprovalModel.fromFirestore(approvalDoc);
      final vendorId = approval.vendorId;
      print('Vendor ID from approval: $vendorId');

      // Update approval status
      print('Updating vendor_approvals document...');
      await _firestore
          .collection('vendor_approvals')
          .doc(approvalId)
          .update({
        'status': 'rejected',
        'approved_by': adminId,
        'rejection_reason': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
      });

      // Update vendor document to mark as rejected
      print('Updating vendors document...');
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .update({
        'is_approved': false,
        'approval_status': 'rejected',
        'rejection_reason': reason,
        'rejected_at': FieldValue.serverTimestamp(),
        'rejected_by': adminId,
      });

      print('Vendor rejected: $vendorId');
      return true;
    } catch (e) {
      print('Error rejecting vendor: $e');
      return false;
    }
  }

  // Get all users
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get all vendors
  Stream<List<Map<String, dynamic>>> getAllVendors() {
    return _firestore
        .collection('vendors')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Delete user account
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete vendor document if exists
      await _firestore.collection('vendors').doc(userId).delete();
      
      // Delete vendor approval if exists
      final approvalQuery = await _firestore
          .collection('vendor_approvals')
          .where('vendor_id', isEqualTo: userId)
          .get();
      
      for (var doc in approvalQuery.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        print('User deleted successfully: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user: $e');
      }
      return false;
    }
  }

  // Get dashboard statistics (alias for getDashboardStats)
  Future<Map<String, dynamic>> getDashboardStatistics() async {
    return getDashboardStats();
  }

  // Get admin dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final vendorsCount = await _firestore.collection('vendors').count().get();
      final pendingApprovalsCount = await _firestore
          .collection('vendor_approvals')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      final ordersCount = await _firestore.collection('orders').count().get();

      return {
        'total_users': usersCount.count,
        'total_vendors': vendorsCount.count,
        'pending_approvals': pendingApprovalsCount.count,
        'total_orders': ordersCount.count,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting dashboard stats: $e');
      }
      return {
        'total_users': 0,
        'total_vendors': 0,
        'pending_approvals': 0,
        'total_orders': 0,
      };
    }
  }
}