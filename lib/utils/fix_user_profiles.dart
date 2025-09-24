import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserProfileFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fix user profile by adding missing contact details
  static Future<void> fixUserProfile(String userId, {
    String? name,
    String? phoneNumber,
    String? campusId,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        
        Map<String, dynamic> updateData = {};
        
        // Add missing fields
        if (data['name'] == null && name != null) {
          updateData['name'] = name;
        }
        if (data['phone_number'] == null && phoneNumber != null) {
          updateData['phone_number'] = phoneNumber;
        }
        if (data['campus_id'] == null && campusId != null) {
          updateData['campus_id'] = campusId;
        }
        
        if (updateData.isNotEmpty) {
          updateData['updated_at'] = FieldValue.serverTimestamp();
          await _firestore.collection('users').doc(userId).update(updateData);
          
          if (kDebugMode) {
            print('Updated user profile for $userId with: $updateData');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fixing user profile for $userId: $e');
      }
      rethrow;
    }
  }

  // Fix all users with missing contact details
  static Future<void> fixAllUserProfiles() async {
    try {
      if (kDebugMode) {
        print('Starting user profile fix...');
      }
      
      final usersSnapshot = await _firestore.collection('users').get();
      int fixedCount = 0;
      
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        
        // Check if user is missing contact details
        if (data['name'] == null || data['phone_number'] == null) {
          Map<String, dynamic> updateData = {};
          
          if (data['name'] == null) {
            updateData['name'] = 'User ${doc.id.substring(0, 8)}';
          }
          if (data['phone_number'] == null) {
            updateData['phone_number'] = '0000000000'; // Placeholder
          }
          if (data['campus_id'] == null) {
            updateData['campus_id'] = 'ID${doc.id.substring(0, 6)}';
          }
          
          if (updateData.isNotEmpty) {
            updateData['updated_at'] = FieldValue.serverTimestamp();
            await _firestore.collection('users').doc(doc.id).update(updateData);
            fixedCount++;
            
            if (kDebugMode) {
              print('Fixed user profile: ${doc.id}');
            }
          }
        }
      }
      
      if (kDebugMode) {
        print('User profile fix completed. Fixed $fixedCount user profiles.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fixing user profiles: $e');
      }
      rethrow;
    }
  }
}
