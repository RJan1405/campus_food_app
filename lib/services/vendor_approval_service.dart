import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/vendor_approval_model.dart';

class VendorApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit vendor approval request
  Future<bool> submitVendorApproval({
    required String shopNumber,
    required double monthlyRent,
    required String document1Url,
    required String document2Url,
    required String document1Name,
    required String document2Name,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if vendor already has a pending or approved request
      final existingApproval = await _firestore
          .collection('vendor_approvals')
          .where('vendor_id', isEqualTo: user.uid)
          .get();

      if (existingApproval.docs.isNotEmpty) {
        if (kDebugMode) {
          print('Vendor already has an approval request');
        }
        return false;
      }

      // Get vendor details
      final vendorDoc = await _firestore
          .collection('vendors')
          .doc(user.uid)
          .get();

      if (!vendorDoc.exists) return false;

      final vendorData = vendorDoc.data()!;

      // Create approval request
      final approvalData = VendorApprovalModel(
        id: '', // Will be set by Firestore
        vendorId: user.uid,
        vendorEmail: user.email ?? '',
        vendorName: vendorData['name'] ?? '',
        shopNumber: shopNumber,
        monthlyRent: monthlyRent,
        document1Url: document1Url,
        document2Url: document2Url,
        document1Name: document1Name,
        document2Name: document2Name,
        status: VendorApprovalStatus.pending,
        submittedAt: DateTime.now(),
        additionalDetails: additionalDetails ?? {},
      );

      await _firestore
          .collection('vendor_approvals')
          .add(approvalData.toFirestore());

      // Update vendor document to mark as pending approval
      await _firestore
          .collection('vendors')
          .doc(user.uid)
          .update({
        'is_approved': false,
        'approval_status': 'pending',
        'shop_number': shopNumber,
        'monthly_rent': monthlyRent,
        'submitted_for_approval_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Vendor approval request submitted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting vendor approval: $e');
      }
      return false;
    }
  }

  // Get vendor approval status for current user
  Future<VendorApprovalModel?> getCurrentVendorApproval() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final approvalQuery = await _firestore
          .collection('vendor_approvals')
          .where('vendor_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (approvalQuery.docs.isNotEmpty) {
        return VendorApprovalModel.fromFirestore(approvalQuery.docs.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor approval: $e');
      }
      return null;
    }
  }

  // Check if vendor is approved
  Future<bool> isVendorApproved() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final vendorDoc = await _firestore
          .collection('vendors')
          .doc(user.uid)
          .get();

      if (!vendorDoc.exists) return false;

      final vendorData = vendorDoc.data()!;
      return vendorData['is_approved'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking vendor approval: $e');
      }
      return false;
    }
  }

  // Get vendor approval status
  Future<String> getVendorApprovalStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'not_vendor';

      final vendorDoc = await _firestore
          .collection('vendors')
          .doc(user.uid)
          .get();

      if (!vendorDoc.exists) return 'not_vendor';

      final vendorData = vendorDoc.data()!;
      return vendorData['approval_status'] ?? 'pending';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor approval status: $e');
      }
      return 'error';
    }
  }

  // Delete vendor account after rejection
  Future<bool> deleteVendorAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Delete vendor document
      await _firestore.collection('vendors').doc(user.uid).delete();
      
      // Delete vendor approval document
      final approvalQuery = await _firestore
          .collection('vendor_approvals')
          .where('vendor_id', isEqualTo: user.uid)
          .get();
      
      for (var doc in approvalQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Sign out user
      await _auth.signOut();

      if (kDebugMode) {
        print('Vendor account deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting vendor account: $e');
      }
      return false;
    }
  }

  // Stream vendor approval status
  Stream<VendorApprovalModel?> getVendorApprovalStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('vendor_approvals')
        .where('vendor_id', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return VendorApprovalModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }
}
