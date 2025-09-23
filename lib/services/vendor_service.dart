import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _vendorsCollection = 
      FirebaseFirestore.instance.collection('vendors');
  final CollectionReference _menuItemsCollection = 
      FirebaseFirestore.instance.collection('menu_items');
  
  // Get all vendors
  Future<List<VendorModel>> getAllVendors() async {
    try {
      QuerySnapshot querySnapshot = await _vendorsCollection.get();
      
      return querySnapshot.docs
          .map((doc) => VendorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendors: $e');
      }
      throw Exception('Failed to get vendors: $e');
    }
  }
  
  // Get open vendors
  Future<List<VendorModel>> getOpenVendors() async {
    try {
      QuerySnapshot querySnapshot = await _vendorsCollection
          .where('is_open', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => VendorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting open vendors: $e');
      }
      throw Exception('Failed to get open vendors: $e');
    }
  }
  
  // Get vendor by ID
  Future<VendorModel> getVendorById(String vendorId) async {
    try {
      DocumentSnapshot doc = await _vendorsCollection.doc(vendorId).get();
      
      if (!doc.exists) {
        throw Exception('Vendor not found');
      }
      
      return VendorModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor: $e');
      }
      throw Exception('Failed to get vendor: $e');
    }
  }
  
  // Get vendor by owner ID
  Future<VendorModel?> getVendorByOwnerId(String ownerId) async {
    try {
      QuerySnapshot querySnapshot = await _vendorsCollection
          .where('owner_id', isEqualTo: ownerId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return VendorModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor by owner: $e');
      }
      throw Exception('Failed to get vendor by owner: $e');
    }
  }
  
  // Search vendors by name or food type
  Future<List<VendorModel>> searchVendors(String query) async {
    try {
      // This is a simple implementation - in a real app, you might use
      // a more sophisticated search solution like Algolia
      QuerySnapshot querySnapshot = await _vendorsCollection.get();
      
      List<VendorModel> vendors = querySnapshot.docs
          .map((doc) => VendorModel.fromFirestore(doc))
          .toList();
      
      // Filter vendors by name or food type containing the query
      return vendors.where((vendor) {
        String name = vendor.name.toLowerCase();
        bool matchesName = name.contains(query.toLowerCase());
        
        bool matchesFoodType = vendor.foodTypes.any(
          (type) => type.toLowerCase().contains(query.toLowerCase())
        );
        
        return matchesName || matchesFoodType;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching vendors: $e');
      }
      throw Exception('Failed to search vendors: $e');
    }
  }
  
  // Get menu items for a vendor
  Future<List<MenuItemModel>> getMenuItems(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('menu_items')
          .where('vendor_id', isEqualTo: vendorId)
          .where('is_available', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting menu items: $e');
      }
      throw Exception('Failed to get menu items: $e');
    }
  }
  
  // Get available menu items for a vendor
  Future<List<MenuItemModel>> getAvailableVendorMenuItems(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _menuItemsCollection
          .where('vendor_id', isEqualTo: vendorId)
          .where('is_available', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available menu items: $e');
      }
      throw Exception('Failed to get available menu items: $e');
    }
  }
  
  // Add a new menu item
  Future<String> addMenuItem(MenuItemModel menuItem) async {
    try {
      DocumentReference docRef = await _menuItemsCollection.add(menuItem.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding menu item: $e');
      }
      throw Exception('Failed to add menu item: $e');
    }
  }
  
  // Update a menu item
  Future<void> updateMenuItem(MenuItemModel menuItem) async {
    try {
      await _menuItemsCollection.doc(menuItem.id).update(menuItem.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating menu item: $e');
      }
      throw Exception('Failed to update menu item: $e');
    }
  }
  
  // Toggle menu item availability
  Future<void> toggleMenuItemAvailability(String menuItemId, bool isAvailable) async {
    try {
      await _menuItemsCollection.doc(menuItemId).update({
        'is_available': isAvailable,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling menu item availability: $e');
      }
      throw Exception('Failed to toggle menu item availability: $e');
    }
  }
  
  // Update vendor status (open/closed)
  Future<void> updateVendorStatus(String vendorId, bool isOpen) async {
    try {
      await _vendorsCollection.doc(vendorId).update({
        'is_open': isOpen,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vendor status: $e');
      }
      throw Exception('Failed to update vendor status: $e');
    }
  }
  
  // Toggle vendor availability
  Future<void> toggleVendorAvailability(String vendorId, bool isOpen) async {
    try {
      await _vendorsCollection.doc(vendorId).update({
        'is_open': isOpen,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling vendor availability: $e');
      }
      throw Exception('Failed to toggle vendor availability: $e');
    }
  }
  
  // Stream of vendor updates
  Stream<VendorModel> vendorStream(String vendorId) {
    return _vendorsCollection
        .doc(vendorId)
        .snapshots()
        .map((doc) => VendorModel.fromFirestore(doc));
  }
  
  // Stream of menu items for a vendor
  Stream<List<MenuItemModel>> vendorMenuItemsStream(String vendorId) {
    return _menuItemsCollection
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList());
  }
}