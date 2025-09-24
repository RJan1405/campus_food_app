import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/vendor_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user contact details by user ID
  Future<Map<String, String?>> getUserContactDetails(String userId) async {
    try {
      if (kDebugMode) {
        print('Fetching contact details for user: $userId');
      }
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (kDebugMode) {
          print('User data found: $data');
        }
        final result = <String, String?>{
          'name': data['name']?.toString() ?? 'Unknown User',
          'phone': data['phone_number']?.toString() ?? 'No phone',
          'email': data['email']?.toString() ?? 'No email',
          'campus_id': data['campus_id']?.toString() ?? 'No ID',
        };
        if (kDebugMode) {
          print('Contact details result: $result');
        }
        return result;
      } else {
        if (kDebugMode) {
          print('User document does not exist for: $userId');
        }
        // Return default values for missing users
        return {
          'name': 'Unknown User',
          'phone': 'No phone',
          'email': 'No email',
          'campus_id': 'No ID',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user contact details: $e');
      }
      // Return default values on error
      return {
        'name': 'Unknown User',
        'phone': 'No phone',
        'email': 'No email',
        'campus_id': 'No ID',
      };
    }
  }

  // Get vendor contact details by vendor ID
  Future<Map<String, String?>> getVendorContactDetails(String vendorId) async {
    try {
      final vendorDoc = await _firestore.collection('vendors').doc(vendorId).get();
      if (vendorDoc.exists) {
        final data = vendorDoc.data() as Map<String, dynamic>;
        return {
          'name': data['name'],
          'phone': data['phone_number'],
          'email': data['email'],
          'owner_name': data['owner_name'],
          'location': data['location'],
        };
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor contact details: $e');
      }
      return {};
    }
  }

  // Get user contact details for an order
  Future<Map<String, String?>> getOrderUserContactDetails(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final userId = orderData['user_id'];
        if (userId != null) {
          return await getUserContactDetails(userId);
        }
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting order user contact details: $e');
      }
      return {};
    }
  }

  // Get vendor contact details for an order
  Future<Map<String, String?>> getOrderVendorContactDetails(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final vendorId = orderData['vendor_id'];
        if (vendorId != null) {
          return await getVendorContactDetails(vendorId);
        }
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting order vendor contact details: $e');
      }
      return {};
    }
  }

  // Update vendor contact details
  Future<bool> updateVendorContactDetails({
    required String vendorId,
    String? phoneNumber,
    String? email,
    String? ownerName,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (email != null) updateData['email'] = email;
      if (ownerName != null) updateData['owner_name'] = ownerName;
      
      if (updateData.isNotEmpty) {
        updateData['updated_at'] = FieldValue.serverTimestamp();
        await _firestore.collection('vendors').doc(vendorId).update(updateData);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vendor contact details: $e');
      }
      return false;
    }
  }

  // Update user contact details
  Future<bool> updateUserContactDetails({
    required String userId,
    String? phoneNumber,
    String? name,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (name != null) updateData['name'] = name;
      
      if (updateData.isNotEmpty) {
        updateData['updated_at'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(userId).update(updateData);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user contact details: $e');
      }
      return false;
    }
  }
}
