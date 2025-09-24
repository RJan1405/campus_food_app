import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite_item_model.dart';
import '../models/menu_item_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add item to favorites
  Future<void> addToFavorites(MenuItemModel menuItem) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if item is already in favorites
      final existingQuery = await _firestore
          .collection('favorites')
          .where('user_id', isEqualTo: user.uid)
          .where('menu_item_id', isEqualTo: menuItem.id)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Item is already in favorites');
      }

      // Get vendor name
      String vendorName = 'Unknown Vendor';
      try {
        final vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(menuItem.vendorId)
            .get();
        if (vendorDoc.exists) {
          vendorName = vendorDoc.data()?['name'] ?? 'Unknown Vendor';
        }
      } catch (e) {
        print('Error getting vendor name: $e');
      }

      final favoriteItem = FavoriteItemModel(
        id: '', // Firestore will generate this
        userId: user.uid,
        menuItemId: menuItem.id,
        menuItemName: menuItem.name,
        vendorId: menuItem.vendorId,
        vendorName: vendorName,
        price: menuItem.price,
        discountedPrice: menuItem.discountedPrice,
        imageUrl: menuItem.imageUrl,
        description: menuItem.description,
        tags: menuItem.ingredients, // Use ingredients as tags
        addedAt: DateTime.now(),
        metadata: {
          'original_menu_item': menuItem.toMap(),
        },
      );

      await _firestore.collection('favorites').add(favoriteItem.toMap());
      
      if (kDebugMode) {
        print('Added to favorites: ${menuItem.name} for user: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to favorites: $e');
      }
      rethrow;
    }
  }

  // Remove item from favorites
  Future<void> removeFromFavorites(String menuItemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('favorites')
          .where('user_id', isEqualTo: user.uid)
          .where('menu_item_id', isEqualTo: menuItemId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('favorites')
            .doc(querySnapshot.docs.first.id)
            .delete();
        
        if (kDebugMode) {
          print('Removed from favorites: $menuItemId for user: ${user.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing from favorites: $e');
      }
      rethrow;
    }
  }

  // Check if item is in favorites
  Future<bool> isFavorite(String menuItemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final querySnapshot = await _firestore
          .collection('favorites')
          .where('user_id', isEqualTo: user.uid)
          .where('menu_item_id', isEqualTo: menuItemId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking favorite status: $e');
      }
      return false;
    }
  }

  // Get user's favorite items
  Stream<List<FavoriteItemModel>> getUserFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          List<FavoriteItemModel> favorites = snapshot.docs
              .map((doc) => FavoriteItemModel.fromFirestore(doc))
              .toList();
          
          // Sort by added_at in memory to avoid index requirement
          favorites.sort((a, b) => b.addedAt.compareTo(a.addedAt));
          
          return favorites;
        });
  }

  // Get favorites grouped by vendor
  Stream<Map<String, List<FavoriteItemModel>>> getUserFavoritesByVendor(String userId) {
    return getUserFavorites(userId).map((favorites) {
      Map<String, List<FavoriteItemModel>> grouped = {};
      for (var favorite in favorites) {
        if (!grouped.containsKey(favorite.vendorId)) {
          grouped[favorite.vendorId] = [];
        }
        grouped[favorite.vendorId]!.add(favorite);
      }
      return grouped;
    });
  }

  // Quick add to cart from favorites
  Future<void> quickAddToCart(FavoriteItemModel favoriteItem, int quantity) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current cart
      final cartDoc = await _firestore
          .collection('carts')
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (cartDoc.docs.isEmpty) {
        throw Exception('Cart not found');
      }

      final cartData = cartDoc.docs.first.data();
      Map<String, List<dynamic>> vendorItems = Map<String, List<dynamic>>.from(
        cartData['vendor_items'] ?? {}
      );

      // Get or create vendor items list
      List<dynamic> vendorItemsList = vendorItems[favoriteItem.vendorId] ?? [];

      // Check if item already exists in cart
      int existingIndex = vendorItemsList.indexWhere(
        (item) => item['menu_item_id'] == favoriteItem.menuItemId
      );

      if (existingIndex >= 0) {
        // Update existing item quantity
        vendorItemsList[existingIndex]['quantity'] = 
            (vendorItemsList[existingIndex]['quantity'] ?? 0) + quantity;
      } else {
        // Add new item
        vendorItemsList.add({
          'menu_item_id': favoriteItem.menuItemId,
          'name': favoriteItem.menuItemName,
          'price': favoriteItem.price,
          'discounted_price': favoriteItem.discountedPrice,
          'quantity': quantity,
          'vendor_id': favoriteItem.vendorId,
          'image_url': favoriteItem.imageUrl,
        });
      }

      // Update vendor items
      vendorItems[favoriteItem.vendorId] = vendorItemsList;

      // Update cart
      await _firestore
          .collection('carts')
          .doc(cartDoc.docs.first.id)
          .update({
        'vendor_items': vendorItems,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Added ${favoriteItem.menuItemName} to cart from favorites');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to cart from favorites: $e');
      }
      rethrow;
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('favorites')
          .where('user_id', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      if (kDebugMode) {
        print('Cleared all favorites for user: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing favorites: $e');
      }
      rethrow;
    }
  }
}
