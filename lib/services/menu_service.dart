import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all menu items for a vendor
  Stream<List<MenuItemModel>> getMenuItems(String vendorId) {
    return _firestore
        .collection('menu_items')
        .where('vendor_id', isEqualTo: vendorId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();
    });
  }

  // Get menu items by category
  Stream<List<MenuItemModel>> getMenuItemsByCategory(String vendorId, String category) {
    return _firestore
        .collection('menu_items')
        .where('vendor_id', isEqualTo: vendorId)
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();
    });
  }

  // Get available menu items only
  Stream<List<MenuItemModel>> getAvailableMenuItems(String vendorId) {
    return _firestore
        .collection('menu_items')
        .where('vendor_id', isEqualTo: vendorId)
        .where('is_available', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();
    });
  }

  // Add a new menu item
  Future<String> addMenuItem(MenuItemModel menuItem) async {
    try {
      if (menuItem.id.isNotEmpty) {
        // Use the provided ID
        await _firestore.collection('menu_items').doc(menuItem.id).set(menuItem.toMap());
        return menuItem.id;
      } else {
        // Let Firestore generate an ID
        final docRef = await _firestore.collection('menu_items').add(menuItem.toMap());
        return docRef.id;
      }
    } catch (e) {
      print('Error adding menu item: $e');
      throw Exception('Failed to add menu item');
    }
  }

  // Update an existing menu item
  Future<void> updateMenuItem(String itemId, MenuItemModel menuItem) async {
    try {
      await _firestore.collection('menu_items').doc(itemId).update(
        menuItem.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      print('Error updating menu item: $e');
      throw Exception('Failed to update menu item');
    }
  }

  // Delete a menu item
  Future<void> deleteMenuItem(String itemId) async {
    try {
      // First, delete the image from storage if it exists
      final doc = await _firestore.collection('menu_items').doc(itemId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await _deleteImageFromStorage(imageUrl);
        }
      }
      
      // Then delete the document
      await _firestore.collection('menu_items').doc(itemId).delete();
    } catch (e) {
      print('Error deleting menu item: $e');
      throw Exception('Failed to delete menu item');
    }
  }

  // Toggle availability of a menu item
  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    try {
      await _firestore.collection('menu_items').doc(itemId).update({
        'is_available': isAvailable,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error toggling availability: $e');
      throw Exception('Failed to update availability');
    }
  }

  // Update stock quantity
  Future<void> updateStockQuantity(String itemId, int quantity) async {
    try {
      await _firestore.collection('menu_items').doc(itemId).update({
        'stock_quantity': quantity,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating stock quantity: $e');
      throw Exception('Failed to update stock quantity');
    }
  }

  // Upload image to Firebase Storage
  Future<String> uploadMenuItemImage(File imageFile, String vendorId, String itemId) async {
    try {
      print('Starting image upload for vendor: $vendorId, item: $itemId');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      
      final fileName = '${vendorId}_${itemId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      print('Generated filename: $fileName');
      
      final ref = _storage.ref().child('menu_items/$fileName');
      print('Storage reference created: ${ref.fullPath}');
      
      print('Starting file upload...');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=31536000',
      );
      final uploadTask = await ref.putFile(imageFile, metadata);
      print('Upload task completed');
      
      print('Getting download URL...');
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('permission')) {
        throw Exception('Permission denied. Please check Firebase Storage rules.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Failed to upload image: ${e.toString()}');
      }
    }
  }

  // Delete image from Firebase Storage
  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image from storage: $e');
      // Don't throw exception here as the main operation should continue
    }
  }

  // Get menu categories for a vendor
  Future<List<String>> getMenuCategories(String vendorId) async {
    try {
      final snapshot = await _firestore
          .collection('menu_items')
          .where('vendor_id', isEqualTo: vendorId)
          .get();
      
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get popular menu items
  Stream<List<MenuItemModel>> getPopularMenuItems(String vendorId) {
    return _firestore
        .collection('menu_items')
        .where('vendor_id', isEqualTo: vendorId)
        .where('is_popular', isEqualTo: true)
        .where('is_available', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();
    });
  }

  // Search menu items
  Future<List<MenuItemModel>> searchMenuItems(String vendorId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('menu_items')
          .where('vendor_id', isEqualTo: vendorId)
          .get();
      
      final items = snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .where((item) => 
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      return items;
    } catch (e) {
      print('Error searching menu items: $e');
      return [];
    }
  }

  // Get menu statistics
  Future<Map<String, dynamic>> getMenuStatistics(String vendorId) async {
    try {
      final snapshot = await _firestore
          .collection('menu_items')
          .where('vendor_id', isEqualTo: vendorId)
          .get();
      
      int totalItems = snapshot.docs.length;
      int availableItems = 0;
      int popularItems = 0;
      double totalRating = 0;
      int totalReviews = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['is_available'] == true) availableItems++;
        if (data['is_popular'] == true) popularItems++;
        totalRating += (data['rating'] ?? 0.0).toDouble();
        totalReviews += (data['review_count'] ?? 0) as int;
      }
      
      final averageRating = totalItems > 0 ? totalRating / totalItems : 0.0;
      
      return {
        'total_items': totalItems,
        'available_items': availableItems,
        'popular_items': popularItems,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
      };
    } catch (e) {
      print('Error getting menu statistics: $e');
      return {
        'total_items': 0,
        'available_items': 0,
        'popular_items': 0,
        'average_rating': 0.0,
        'total_reviews': 0,
      };
    }
  }
}
