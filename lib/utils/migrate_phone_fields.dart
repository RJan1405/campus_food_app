import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PhoneFieldMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate user documents from 'phone' to 'phone_number'
  static Future<void> migrateUserPhoneFields() async {
    try {
      print('Starting migration of user phone fields...');
      
      // Get all user documents
      final usersSnapshot = await _firestore.collection('users').get();
      
      int migratedCount = 0;
      
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        
        // Check if document has 'phone' field but not 'phone_number'
        if (data.containsKey('phone') && !data.containsKey('phone_number')) {
          final phoneValue = data['phone'];
          
          // Update the document to use 'phone_number' instead of 'phone'
          await _firestore.collection('users').doc(doc.id).update({
            'phone_number': phoneValue,
          });
          
          // Remove the old 'phone' field
          await _firestore.collection('users').doc(doc.id).update({
            'phone': FieldValue.delete(),
          });
          
          migratedCount++;
          print('Migrated user document: ${doc.id}');
        }
      }
      
      print('Migration completed. Migrated $migratedCount user documents.');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  // Migrate vendor documents from 'phone' to 'phone_number'
  static Future<void> migrateVendorPhoneFields() async {
    try {
      print('Starting migration of vendor phone fields...');
      
      // Get all vendor documents
      final vendorsSnapshot = await _firestore.collection('vendors').get();
      
      int migratedCount = 0;
      
      for (final doc in vendorsSnapshot.docs) {
        final data = doc.data();
        
        // Check if document has 'phone' field but not 'phone_number'
        if (data.containsKey('phone') && !data.containsKey('phone_number')) {
          final phoneValue = data['phone'];
          
          // Update the document to use 'phone_number' instead of 'phone'
          await _firestore.collection('vendors').doc(doc.id).update({
            'phone_number': phoneValue,
          });
          
          // Remove the old 'phone' field
          await _firestore.collection('vendors').doc(doc.id).update({
            'phone': FieldValue.delete(),
          });
          
          migratedCount++;
          print('Migrated vendor document: ${doc.id}');
        }
      }
      
      print('Migration completed. Migrated $migratedCount vendor documents.');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  // Run both migrations
  static Future<void> runAllMigrations() async {
    try {
      await migrateUserPhoneFields();
      await migrateVendorPhoneFields();
      print('All migrations completed successfully!');
    } catch (e) {
      print('Migration failed: $e');
      rethrow;
    }
  }
}
