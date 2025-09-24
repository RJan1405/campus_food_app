import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String menuItemId;
  final String vendorId;
  final String name;
  final int quantity;
  final double price;
  final double discountedPrice;
  final String? imageUrl;
  
  CartItemModel({
    required this.menuItemId,
    required this.vendorId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
    this.imageUrl,
  });
  
  factory CartItemModel.fromMap(Map<String, dynamic> data) {
    return CartItemModel(
      menuItemId: data['menu_item_id'] ?? '',
      vendorId: data['vendor_id'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      discountedPrice: (data['discounted_price'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'menu_item_id': menuItemId,
      'vendor_id': vendorId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'discounted_price': discountedPrice,
      'image_url': imageUrl,
    };
  }
  
  CartItemModel copyWith({
    String? menuItemId,
    String? vendorId,
    String? name,
    int? quantity,
    double? price,
    double? discountedPrice,
    String? imageUrl,
  }) {
    return CartItemModel(
      menuItemId: menuItemId ?? this.menuItemId,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class CartModel {
  final String userId;
  final Map<String, List<CartItemModel>> vendorItems; // Multiple vendors supported
  final double subtotal;
  final double discount;
  final double total;
  
  CartModel({
    required this.userId,
    required this.vendorItems,
    required this.subtotal,
    required this.discount,
    required this.total,
  });
  
  factory CartModel.empty(String userId) {
    return CartModel(
      userId: userId,
      vendorItems: {},
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    );
  }
  
  factory CartModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    Map<String, List<CartItemModel>> vendorItems = {};
    
    if (data['vendor_items'] != null) {
      Map<String, dynamic> vendorItemsData = data['vendor_items'] as Map<String, dynamic>;
      vendorItemsData.forEach((vendorId, itemsList) {
        if (itemsList is List) {
          vendorItems[vendorId] = itemsList.map((item) => 
            CartItemModel.fromMap(item as Map<String, dynamic>)
          ).toList();
        }
      });
    }
    
    return CartModel(
      userId: data['user_id'] ?? '',
      vendorItems: vendorItems,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    Map<String, dynamic> vendorItemsMap = {};
    vendorItems.forEach((vendorId, items) {
      vendorItemsMap[vendorId] = items.map((item) => item.toMap()).toList();
    });
    
    return {
      'user_id': userId,
      'vendor_items': vendorItemsMap,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
    };
  }
  
  // Helper methods
  bool get isEmpty => vendorItems.isEmpty;
  int get itemCount => vendorItems.values
      .expand((items) => items)
      .fold(0, (sum, item) => sum + item.quantity);
  
  // Get all items from all vendors
  List<CartItemModel> get allItems => vendorItems.values
      .expand((items) => items)
      .toList();
  
  // Get items for a specific vendor
  List<CartItemModel> getItemsForVendor(String vendorId) {
    return vendorItems[vendorId] ?? [];
  }
  
  // Get all vendor IDs
  List<String> get vendorIds => vendorItems.keys.toList();
  
  // Calculate totals based on current items
  CartModel recalculate() {
    double newSubtotal = 0.0;
    double newDiscount = 0.0;
    
    for (var items in vendorItems.values) {
      for (var item in items) {
        newSubtotal += item.price * item.quantity;
        newDiscount += (item.price - item.discountedPrice) * item.quantity;
      }
    }
    
    return CartModel(
      userId: userId,
      vendorItems: vendorItems,
      subtotal: newSubtotal,
      discount: newDiscount,
      total: newSubtotal - newDiscount,
    );
  }
  
  // Add item to cart
  CartModel addItem(CartItemModel newItem) {
    Map<String, List<CartItemModel>> updatedVendorItems = Map.from(vendorItems);
    
    // Get or create the list for this vendor
    List<CartItemModel> vendorItemsList = updatedVendorItems[newItem.vendorId] ?? [];
    
    // Check if item already exists in this vendor's items
    int existingIndex = vendorItemsList.indexWhere((item) => item.menuItemId == newItem.menuItemId);
    
    if (existingIndex >= 0) {
      // Update existing item quantity
      CartItemModel existingItem = vendorItemsList[existingIndex];
      vendorItemsList[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + newItem.quantity
      );
    } else {
      // Add new item
      vendorItemsList.add(newItem);
    }
    
    // Update the vendor items map
    updatedVendorItems[newItem.vendorId] = vendorItemsList;
    
    return CartModel(
      userId: userId,
      vendorItems: updatedVendorItems,
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    ).recalculate();
  }
  
  // Remove item from cart
  CartModel removeItem(String menuItemId) {
    Map<String, List<CartItemModel>> updatedVendorItems = {};
    
    vendorItems.forEach((vendorId, items) {
      List<CartItemModel> filteredItems = items.where((item) => item.menuItemId != menuItemId).toList();
      if (filteredItems.isNotEmpty) {
        updatedVendorItems[vendorId] = filteredItems;
      }
    });
    
    return CartModel(
      userId: userId,
      vendorItems: updatedVendorItems,
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    ).recalculate();
  }
  
  // Update item quantity
  CartModel updateItemQuantity(String menuItemId, int quantity) {
    Map<String, List<CartItemModel>> updatedVendorItems = {};
    
    vendorItems.forEach((vendorId, items) {
      List<CartItemModel> updatedItems = List.from(items);
      int itemIndex = items.indexWhere((item) => item.menuItemId == menuItemId);
      
      if (itemIndex >= 0) {
        if (quantity <= 0) {
          updatedItems.removeAt(itemIndex);
        } else {
          updatedItems[itemIndex] = items[itemIndex].copyWith(quantity: quantity);
        }
      }
      
      if (updatedItems.isNotEmpty) {
        updatedVendorItems[vendorId] = updatedItems;
      }
    });
    
    return CartModel(
      userId: userId,
      vendorItems: updatedVendorItems,
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    ).recalculate();
  }
  
  // Clear cart
  CartModel clear() {
    return CartModel.empty(userId);
  }
}